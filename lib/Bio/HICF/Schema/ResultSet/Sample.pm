use utf8;
package Bio::HICF::Schema::ResultSet::Sample;

use Moose;
use MooseX::NonMoose;
use MooseX::Params::Validate;
use Carp qw ( croak );

extends 'DBIx::Class::ResultSet';

sub BUILDARGS { $_[2] }
# see https://metacpan.org/pod/DBIx::Class::ResultSet#ResultSet-subclassing-with-Moose-and-similar-constructor-providers

#-------------------------------------------------------------------------------

# ABSTRACT: resultset for the sample table

=head1 METHODS

=head2 load($upload)

Loads a row into the C<sample> table using values from the C<$upload> hash. The
hash should contain column values keyed on column names.

The same sample may be loaded multiple times, subject to the constraint that it
comes from a different manifest each time.

Further validation checks are applied before loading, such as confirming that
the tax ID and scientific name match. An exception is thrown if any of these
checks fail. Columns that permit "unknown" as a valid value are also checked
for accepted values of "unknown".

=cut

sub load {
  my ( $self, $upload ) = @_;

  croak 'not a valid row' unless ref $upload eq 'HASH';

  # validate the various taxonomy fields
  $self->_taxonomy_checks($upload);

  # check that the ontology terms exist
  $self->_ontology_term_check($upload);

  # parse out the antimicrobial resistance data and put them back into the row
  # hash in a format that means they'll get inserted correctly in the child
  # table
  if ( my $amr_string = delete $upload->{antimicrobial_resistance} ) {
    $upload->{antimicrobial_resistances} = $self->_parse_amr_string($amr_string);
  }

  # create a new row for this sample. We want a new row even if this sample
  # already exists, so that we can have keep track of updated samples.

  # first, see if this sample already exists
  my $existing_rs = $self->search(
    {
      raw_data_accession => $upload->{raw_data_accession},
      sample_accession   => $upload->{sample_accession},
      deleted_at => { '=' => undef }
    },
    {}
  );

  # there should only ever be one sample in this set, since we should be be
  # setting existing rows as deleted everytime, so we could just use '->single'
  # to get that row. Just in case, though, we'll apply the 'deleted_at' update
  # to all rows in the set
  warn "WARNING: found multiple live samples with sample accession '$upload->{sample_accession}'"
    if $existing_rs->count;

  while( my $existing_sample = $existing_rs->next ) {
    $existing_sample->mark_as_deleted;

    # mark related rows as deleted
    $_->mark_as_deleted for $existing_sample->search_related('antimicrobial_resistances')->all;
  }

  # finally, create the row
  my $rs = $self->create( $upload, { key => 'manifest_uc' } );

  return $rs->sample_id;
}

#-------------------------------------------------------------------------------

=head2 all_rs(?$include_deleted)

Returns a L<DBIx::Class::ResultSet|ResultSet> containing all samples in the
database, sorted by ascending sample ID and created date, i.e. the most
recently loaded samples will be last in the list.

If C<?$include_deleted> is true, the returned set of samples  will include
those samples that have been deleted, i.e. have "deleted_at" set. The default
is to return only live samples.

=cut

sub all_rs {
  my ( $self, $include_deleted ) = @_;

  my $query = $include_deleted
            ? { }
            : { deleted_at => { '=', undef } };

  return $self->search(
    $query,
    { order_by => { -asc => [qw( sample_id created_at )] } }
  );
}

#-------------------------------------------------------------------------------
#- method modifiers ------------------------------------------------------------
#-------------------------------------------------------------------------------

# when a Sample is marked as deleted, also mark related AntimicrobialResistance
# rows as deleted

after 'delete' => sub {
  my $self = shift;
  $_->mark_as_deleted for $self->search_related('antimicrobial_resistances')->all;
};


#-------------------------------------------------------------------------------
#- private methods -------------------------------------------------------------
#-------------------------------------------------------------------------------

# validate the amr string using a pre-defined type, then parse it and return it
# as a data structure to drop into sample data
sub _parse_amr_string {
  my $self = shift;
  my ( $amr_string ) = pos_validated_list(
    \@_,
    { isa => 'Bio::Metadata::Types::AMRString' },
  );

  # TODO there must be a way to put a big regex like this into a common file
  # TODO like the Types module, rather than having to cart it around like this
  my $amr = [];
  while ( $amr_string =~ m/(([A-Za-z0-9\-\/\(\)\s]+);([SIR]);(lt|le|eq|gt|ge)?(\d+)(;(\w+))?),?\s*/g) {
    push @$amr, {
      antimicrobial_name => $2,
      susceptibility     => $3,
      mic                => $5,
      equality           => $4 || 'eq',
      diagnostic_centre  => $7
    }
  }
  return $amr;
}

#-------------------------------------------------------------------------------

# runs two checks on the taxonomy information in the upload
sub _taxonomy_checks {
  my ( $self, $upload ) = @_;

  my $rs = $self->result_source
                ->schema
                ->resultset('Taxonomy');

  $self->_tax_id_name_check( $rs, $upload );
  $self->_specific_host_check( $rs, $upload );
}

#-------------------------------------------------------------------------------

# taxonomy ID/scientific name consistency check
sub _tax_id_name_check {
  my ( $self, $tax_table, $upload ) = @_;

  my $tax_id = $upload->{tax_id};
  my $name   = $upload->{scientific_name};

  my $schema = $self->result_source->schema;

  # we can only validate taxonomy ID/name if we have both
  return unless ( defined $tax_id and defined $name );

  # additionally, we can't cross-validate if either one is "unknown"
  return if ( $schema->is_accepted_unknown($tax_id) or
              $schema->is_accepted_unknown($name) );

  # find tax ID(s) using the given name. There can, it appears, be multiple
  # nodes with different tax IDs but the same scientific name, so we need to
  # take that into account
  my $rs = $tax_table->search( { name => $name }, {} );

  croak "taxonomy ID not found for scientific name '$name'"
    unless $rs->count;

  my %tax_id_lookup = map { $_->tax_id => 1 } $rs->all;

  # find scientific name using given tax ID
  my $name_lookup = $tax_table->find( { tax_id => $tax_id },
                                      { key => 'primary' } );

  croak "scientific name not found for taxonomy ID ($tax_id)"
    unless defined $name_lookup;

  # cross-check the name and tax ID
  croak "taxonomy ID ($tax_id) and scientific name ($name) do not match"
   unless ( $name_lookup->name eq $name and
            exists $tax_id_lookup{$tax_id} );
}

#-------------------------------------------------------------------------------

# check specific host is a valid scientific name
sub _specific_host_check {
  my ( $self, $tax_table, $upload ) = @_;

  my $name = $upload->{specific_host};

  return if not defined $name;
  return if $self->result_source->schema->is_accepted_unknown($name);

  my $name_lookup = $tax_table->search( { name => $name }, {} );

  croak "species name in 'specific_host' ($name) is not found in the taxonomy tree"
    unless $name_lookup->count;
}

#-------------------------------------------------------------------------------

# check ontology terms are found
sub _ontology_term_check {
  my ( $self, $upload ) = @_;

  my $schema = $self->result_source->schema;

  # the "location" field (gazetteer ontology)
  my $gaz_id = $upload->{location};
  if ( defined $gaz_id and not $schema->is_accepted_unknown($gaz_id) ) {
    my $rs = $schema->resultset('Gazetteer')->find(
      { id  => $gaz_id },
      { key => 'primary' }
    );
    croak "term in 'location' ($gaz_id) is not found in the gazetteer ontology"
      unless defined $rs;
  }

  # "host_isolation_source" field (BRENDA ontology)
  my $brenda_id = $upload->{host_isolation_source};
  if ( defined $brenda_id and not $schema->is_accepted_unknown($brenda_id) ) {
    my $rs = $schema->resultset('Brenda')->find(
      { id  => $brenda_id },
      { key => 'primary' }
    );
    croak "term in 'host_isolation_source' ($brenda_id) is not found in the BRENDA ontology"
      unless defined $rs;
  }

  # "isolation_source" field (EnvO ontology)
  my $envo_id = $upload->{isolation_source};
  if ( defined $envo_id and not $schema->is_accepted_unknown($envo_id) ) {
    my $rs = $schema->resultset('Envo')->find(
      { id  => $envo_id },
      { key => 'primary' }
    );
    croak "term in 'isolation_source' ($envo_id) is not found in the EnvO ontology"
      unless defined $rs;
  }
}

#-------------------------------------------------------------------------------

sub _columns_accepting_unknown {
  return {
    collection_date       => 1,
    location              => 1,
    host_associated       => 1,
    specific_host         => 1,
    host_disease_status   => 1,
    host_isolation_source => 1,
    patient_location      => 1,
    isolation_source      => 1,
    serovar               => 1,
    other_classification  => 1,
  };
}

# returns true if the specified column accepts "unknown" as a value, 0
# otherwise
sub _accepts_unknown {
  my ( $self, $column_name ) = @_;
  return exists $self->_columns_accepting_unknown->{$column_name} || 0;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;
