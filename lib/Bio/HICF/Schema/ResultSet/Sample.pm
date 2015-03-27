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

=head2 load_row($upload)

Loads a row into the C<sample> table using values from the supplied hash. The
hash should contain column values keyed on column names.

The same sample may be loaded multiple times, subject to the constraint that it
comes from a different manifest each time.

Further validation checks are applied before loading, such as confirming that
the tax ID and scientific name match. An exception is thrown if any of these
checks fail.

=cut

sub load_row {
  my ( $self, $upload ) = @_;

  croak 'not a valid row' unless ref $upload eq 'HASH';

  # validate the various taxonomy fields
  $self->_taxonomy_checks($upload);
  # TODO take into account "unknown"

  # check that the ontology terms exist
  $self->_ontology_term_check($upload);
  # TODO take into account "unknown"

  # parse out the antimicrobial resistance data and put them back into the row
  # hash in a format that means they'll get inserted correctly in the child
  # table
  if ( my $amr_string = delete $upload->{antimicrobial_resistance} ) {
    $upload->{antimicrobial_resistances} = $self->_parse_amr_string($amr_string);
  }

  # create a new row for this sample. We want a new row even if this sample
  # already exists, so that we can have keep track of updated samples.
  my $rs = $self->create( $upload, { key => 'sample_uc' } );

  return $rs->sample_id;
}

#-------------------------------------------------------------------------------

=head2 all_rs

Returns a L<DBIx::Class::ResultSet|ResultSet> containing all samples, sorted
by sample ID and created date.

=cut

sub all_rs {
  my ( $self ) = @_;

  return $self->search(
    {},
    { order_by => { -asc => [qw( sample_id created_at )] } }
  );
}

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
  my ( $self, $rs, $upload ) = @_;

  my $tax_id = $upload->{tax_id};
  my $name   = $upload->{scientific_name};

  # we can only validate taxonomy ID/name if we have both
  return unless ( defined $tax_id and defined $name );

  # find tax ID using the given name
  my $tax_id_lookup = $rs->find( { name => $name },
                                 { key => 'name_uq' } );

  croak "taxonomy ID not found for scientific name ($name)"
    unless defined $tax_id_lookup;

  # find scientific name using given tax ID
  my $name_lookup = $rs->find( { tax_id => $tax_id },
                               { key => 'primary' } );

  croak "scientific name not found for taxonomy ID ($tax_id)"
    unless defined $name_lookup;

  # cross-check the name and tax ID
  croak "taxonomy ID ($tax_id) and scientific name ($name) do not match"
   unless ( $tax_id == $tax_id_lookup->tax_id and
            $name   eq $name_lookup->name );
}

#-------------------------------------------------------------------------------

# check specific host is a valid scientific name
sub _specific_host_check {
  my ( $self, $rs, $upload ) = @_;

  my $name = $upload->{specific_host};

  return unless defined $name;

  my $name_lookup = $rs->find( { name => $name },
                               { key => 'name_uq' } );

  croak "species name in 'specific_host' ($name) is not found in the taxonomy tree"
    unless defined $name_lookup;
}

#-------------------------------------------------------------------------------

# check ontology terms are found
sub _ontology_term_check {
  my ( $self, $upload ) = @_;

  my $gaz_id    = $upload->{location};
  my $brenda_id = $upload->{host_isolation_source};
  my $envo_id   = $upload->{isolation_source};

  my $schema = $self->result_source->schema;

  # the "location" field is mandatory, so we'll always check the gazetteer term
  my $rs = $schema->resultset('Gazetteer')
                  ->find( { id => $gaz_id },
                          { key => 'primary' } );
  croak 'term in "location" is not found in the gazetteer ontology'
    unless defined $rs;

  # check BRENDA and EnvO if found
  if ( defined $brenda_id ) {
    $rs = $schema->resultset('Brenda')
                 ->find( { id => $brenda_id },
                         { key => 'primary' } );
    croak 'term in "host_isolation_source" is not found in the BRENDA ontology'
      unless defined $rs;
  }

  if ( defined $envo_id ) {
    $rs = $schema->resultset('Envo')
                 ->find( { id => $envo_id },
                         { key => 'primary' } );
    croak 'term in "isolation_source" is not found in the EnvO ontology'
      unless defined $rs;
  }
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;
