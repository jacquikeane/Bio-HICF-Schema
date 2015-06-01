use utf8;
package Bio::HICF::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-01-13 15:26:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/Tydb6euSFy7u3YcKYKMrA

# ABSTRACT: DBIC schema for the HICF repository

=head1 SYNOPSIS

 # read in a manifest
 my $c = Bio::Metadata::Config->new( config_file => 'hicf.conf' );
 my $r = Bio::Metadata::Reader->new( config => $c );
 my $m = $r->read_csv( 'hicf.csv' );

 # load it into the database
 my $schema = Bio::HICF::Schema->connect( $dsn, $username, $password );
 my @sample_ids = $schema->load_manifest($m);

=cut

use MooseX::Params::Validate;
use Carp qw( croak );
use Try::Tiny;
use Email::Valid;
use File::Basename;
use List::MoreUtils qw( mesh );

use Bio::Metadata::Types qw( UUID OntologyTerm );
use Bio::Metadata::Checklist;
use Bio::Metadata::Validator;
use Bio::Metadata::TaxTree;

#-------------------------------------------------------------------------------

=head1 DESCRIPTION

This is the L<DBIx::Class::Schema> class for the HICF database API. It contains
high-level methods for interacting with the database, notably the methods for
loading most types of data.

=head1 METHODS

=cut

#-------------------------------------------------------------------------------
#- unknown terms ---------------------------------------------------------------
#-------------------------------------------------------------------------------

=head2 unknown_terms

Returns a reference to a hash containing the accepted terms for "unknown" as
keys.

B<Note>: this is the canonical source for this list.

=cut

sub unknown_terms {
  return {
    'not available; not collected'                        => 1,
    'not available; restricted access'                    => 1,
    'not available; to be reported later (35 characters)' => 1,
    'not applicable'                                      => 1,
    'obscured'                                            => 1,
    'temporarily obscured'                                => 1,
  };
}

#-------------------------------------------------------------------------------

=head2 is_accepted_unknown($value)

Returns 1 if the supplied value is one of the accepted terms for "unknown" or
0 otherwise.

=cut

sub is_accepted_unknown {
  my ( $self, $term ) = @_;

  return 0 unless defined $term;
  return exists $self->unknown_terms->{$term} || 0;
}

#-------------------------------------------------------------------------------
#- manifests -------------------------------------------------------------------
#-------------------------------------------------------------------------------

=head2 load_manifest($manifest)

Loads the sample data in a L<Bio::Metadata::Manifest>. Returns a list of the
sample IDs for the newly inserted rows. See
L<Bio::HICF::Schema::ResultSet::Manifest::load>.

=cut

sub load_manifest {
  my ( $self, $manifest ) = @_;

  return $self->resultset('Manifest')->load($manifest);
}

#-------------------------------------------------------------------------------

=head2 get_manifest($manifest_id, ?$include_deleted)

Returns the L<Bio::HICF::Schema::Result::Manifest> with the specified ID.
Returns C<undef> if there is no manifest with that ID. Throws an exception if
the manifest ID is not supplied or is not valid.

=cut

sub get_manifest {
  my ( $self, $mid, $include_deleted ) = @_;

  croak 'ERROR: must supply a valid manifest ID' unless defined $mid;

  croak "ERROR: not a valid manifest ID ($mid)"
    unless is_UUID($mid);

  my $query = { manifest_id => $mid,
                deleted_at  => { '=', undef } };

  delete $query->{deleted_at} if $include_deleted;

  return $self->resultset('Manifest')
              ->search( $query, { prefetch => [ 'checklist' ] } )
              ->single;
}

#-------------------------------------------------------------------------------

=head2 get_manifest_object($manifest_id)

Returns a L<Bio::Metadata::Manifest> object for the specified manifest.
Returns C<undef> if there is no manifest with that ID. Throws an exception if
the manifest ID is not supplied or is not valid.

=cut

sub get_manifest_object {
  my ( $self, $mid, $include_deleted ) = @_;

  my $manifest_row = $self->get_manifest($mid, $include_deleted);

  return unless $manifest_row;

  # create a Bio::Metadata::Checklist for this manifest
  my $checklist_row = $manifest_row->checklist;

  my $checklist_name   = $checklist_row->name;
  my $checklist_config = $checklist_row->config;

  my $constructor_args = { config_string => $checklist_config };

  $constructor_args->{config_name} = $checklist_name
    if defined $checklist_name;

  my $c = Bio::Metadata::Checklist->new(%$constructor_args);

  my @values;
  push @values, $_->field_values for ( $manifest_row->get_samples );

  return Bio::Metadata::Manifest->new( checklist => $c, rows => \@values );
}

#-------------------------------------------------------------------------------

=head2 load_assembly($file_path)

Loads the specified filename as an assembly file. The file must conform to a
particular format: see L<Bio::HICF::Schema::ResultSet::Assembly>. Returns the
loaded row, a L<Bio::HICF::Schema::Result::Assembly> object.

=cut

sub load_file {
  my ( $self, $file_path ) = @_;

  return $self->resultset('Assembly')->load($file_path);
}

#-------------------------------------------------------------------------------

# TODO re-implement this after adding something like
# TODO Bio::HICF::Schema::Role::Manifest::get_samples_values

# sub get_manifest {
#   my ( $self, $manifest_id, $include_deleted ) = @_;
#
#   croak 'ERROR: must supply a valid manifest ID' unless defined $manifest_id;
#
#   croak "ERROR: not a valid manifest ID ($manifest_id)"
#     unless $manifest=~ m/^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$/i;
#
#   # create a B::M::Checklist object from the config string that we have stored
#   # for this manifest
#   my $manifest_row = $self->resultset('Manifest')
#                           ->search( { manifest_id => $manifest_id },
#                                     { prefetch => [ 'checklist' ] } )
#                           ->single;
#
#   return unless $manifest_row;
#
#   my %args = ( config_string => $manifest_row->checklist->config );
#
#   $args{config_name} = $manifest_row->checklist->name
#     if defined $manifest_row->checklist->name;
#
#   my $c = Bio::Metadata::Checklist->new(%args);
#
#   # get the values for the samples in the manifest and add them to a new
#   # B::M::Manifest
#   my $values = $self->get_samples_values($manifest_id);
#   my $m = Bio::Metadata::Manifest->new( checklist => $c, rows => $values );
#
#   return $m;
# }

#-------------------------------------------------------------------------------
#- samples ---------------------------------------------------------------------
#-------------------------------------------------------------------------------

=head2 get_sample_by_accession($acc)

Given a sample accession, C<$acc>, this method returns the most recent version
of the sample. B<Note> that the returned sample may be deleted (has its
C<deleted_at> field set); check if a sample is deleted using
L<Bio::HICF::Schema::Result::Sample::is_deleted|is_deleted>.

Returns C<undef> if there is no sample with the given accession. Throws an
exception if C<$acc> is not supplied.

=cut

sub get_sample_by_accession {
  my ( $self, $acc ) = @_;

  my @versions = $self->get_sample_versions_by_accession($acc);
  return unless @versions;
  return shift @versions;
}

#-------------------------------------------------------------------------------

=head2 get_sample_versions_by_accession($acc)

Returns a list of all versions of the sample with the given accession,
including deleted samples. The list is ordered with the most recent versions
first, i.e. you can retrieve the current, live version of a sample using
something like:

 my @versions = $schema->get_sample_versions_by_accession('ERS123456');
 my $latest = $versions[0];

Returns C<undef> if there is no sample with the given accession. Throws an
exception if C<$acc> is not supplied.

=cut

sub get_sample_versions_by_accession {
  my ( $self, $acc ) = @_;

  croak 'ERROR: must supply a sample accession' unless defined $acc;

  my $rs = $self->resultset('Sample')->search(
    { sample_accession => $acc },
    { order_by => { -desc => ['sample_id'] } },
  );

  return unless $rs;
  return $rs->all;
}

#-------------------------------------------------------------------------------

=head2 get_sample_by_id($id)

Returns the sample with the given ID. This may not be the most recent version
of a sample, since re-loading metadata for a given sample will cause the
existing row to be flagged as deleted and will generate a new row with a new
sample ID. If you give ID for an older, superceded sample, that sample may
(should) have been flagged as deleted (had its C<deleted_at> field set); check
if a sample is deleted using
L<Bio::HICF::Schema::Result::Sample::is_deleted|is_deleted>.

Returns C<undef> if there is no sample with the given ID. Throws an exception
if C<$ID> is not supplied.

=cut

sub get_sample_by_id {
  my ( $self, $id ) = @_;

  croak 'ERROR: must supply a sample ID' unless defined $id;

  return $self->resultset('Sample')->find($id);
}

#-------------------------------------------------------------------------------

=head2 get_samples_in_manifest($manifest_id, ?$include_deleted)

Given a manifest ID, this method returns a L<DBIx::Class::ResultSet|ResultSet>
with all of the samples in that manifest.

If C<$include_deleted> is true, the L<DBIx::Class::ResultSet|ResultSet> will
contain both live (not deleted) and deleted rows. When a sample row is
re-loaded, it must have a different manifest ID, so you may find that, when you
run C<get_samples_in_manifest> with C<$include_deleted> set to true, the
returned samples will contain some that are deleted, because they have been
superceded by the same sample from a different manifest.

If C<$include_deleted> is false or omitted, the
L<DBIx::Class::ResultSet|ResultSet> will contain only live samples, i.e. those
not marked as deleted. B<Note> that this means that any superceded samples will
be omitted from the result set.

=cut

sub get_samples_in_manifest {
  my ( $self, $mid, $include_deleted ) = @_;

  croak 'ERROR: must supply a valid manifest ID'
    unless ( defined $mid and is_UUID($mid) );

  return unless my $manifest_row = $self->resultset('Manifest')->find($mid);

  my $query = { 'manifest.manifest_id' => $mid };

  $query->{'me.deleted_at'} = { '=', undef }
    unless $include_deleted;

  return $self->resultset('Sample')
              ->search( $query, { join => [ 'manifest' ] } );
}

#-------------------------------------------------------------------------------

=head2 get_all_samples

Returns a L<DBIx::Class::ResultSet|ResultSet> containing all samples in the
database.

The sample table is joined against the ontology and geocoding tables,
adding two relationships, C<geolocation>, which adds columns C<lat> and C<long>
(which have values providing the sample location has been geocoded), and
C<location_description>, which links to the gazetteer ontology and provides
the C<description> column, giving the location description from the ontology.

=cut

sub get_all_samples {
  my ( $self ) = @_;

  my $samples_rs = $self->resultset('Sample')->search(
    {},
    {
      join     => [qw( geolocation location_description )],
      prefetch => [qw( geolocation location_description )]
    }
  );

  return $samples_rs;
}

#-------------------------------------------------------------------------------
#- assemblies ------------------------------------------------------------------
#-------------------------------------------------------------------------------

=head2 load_assembly

Given a path to an assembly file, this method stores the file location in the
L<Bio::HICF::Schema::Result::File|File> and
L<Bio::HICF::Schema::Result::Assembly|Assembly> tables.

=cut

sub load_assembly {
  my ( $self, $path ) = @_;

  $self->resultset('Assembly')->load($path);
}

#-------------------------------------------------------------------------------
#- antimicrobial resistance methods --------------------------------------------
#-------------------------------------------------------------------------------

=head2 load_antimicrobial($name)

Adds the specified antimicrobial compound name to the database. Throws an
exception if the supplied name is invalid, e.g. contains non-word characters.

=cut

sub load_antimicrobial {
  my ( $self, $name ) = @_;

  chomp $name;

  try {
    $self->resultset('Antimicrobial')->load($name);
  } catch {
    if ( m/did not pass/ ) {
      croak "ERROR: couldn't load '$name'; invalid antimicrobial compound name";
    }
    default { die $_ }
  };
}

#-------------------------------------------------------------------------------

=head2 load_antimicrobial_resistance(%amr)

Loads a new antimicrobial resistance test result into the database. See
L<Bio::HICF::Schema::ResultSet::AntimicrobialResistance::load>
for details.

=cut

sub load_antimicrobial_resistance {
  my ( $self, %amr ) = @_;
  $self->resultset('AntimicrobialResistance')->load(%amr);
}

#-------------------------------------------------------------------------------
#- taxonomy and ontology methods -----------------------------------------------
#-------------------------------------------------------------------------------

=head2 load_tax_tree($tree, $?slice_size)

load the given tree into the taxonomy table.
See L<Bio::HICF::Schema::ResultSet::Taxonomy::load>.

=cut

sub load_tax_tree {
  my ( $self, $tree, $slice_size ) = @_;

  $self->resultset('Taxonomy')->load($tree, $slice_size);
}

#-------------------------------------------------------------------------------

=head2 load_ontology($table, $file, $?slice_size)

load the given ontology file into the specified table. Requires the name of the
table to load, which must be one of "gazetteer", "envo", or "brenda".  Requires
the path to the ontology file to be loaded. Since the ontologies may be large,
the terms are loaded in chunks of 10,000 at a time. This "slice size" can be
overridden with the C<$slice_size> parameter.

B<Note> that the specified table is emptied before loading.

Throws exceptions if loading fails. If possible, the entire transaction,
including the table truncation and any subsequent loading, will be rolled back.
If roll back fails, the error message will contain the string C<roll back
failed>.

=cut

sub load_ontology {
  my $self = shift;
  my ( $table, $file, $slice_size ) = pos_validated_list(
    \@_,
    { isa => 'Bio::Metadata::Types::OntologyName' },
    { isa => 'Str' },
    { isa => 'Bio::Metadata::Types::PositiveInt', optional => 1 },
  );
  # TODO the error message that comes back from the validation call is dumb
  # TODO and ugly. Just validate the ontology name ourselves and throw a
  # TODO sensible error

  croak "ERROR: ontology file not found ($file)"
    unless ( defined $file and -f $file );

  open ( FILE, $file )
    or croak "ERROR: can't open ontology file ($file): $!";

  $slice_size ||= 10_000;
  my $rs_name = ucfirst $table;
  my $rs = $self->resultset($rs_name);

  # wrap this whole operation in a transaction
  my $txn = sub {

    # before we start, truncate the table
    $rs->delete;

    # walk the file and load it in chunks
    my $chunk   = [ [ 'id', 'description' ] ];  # loading chunk
    my $term    = [];                           # current term
    my $is_term = 0;                            # is the current block a [Term] ?
    my $n       = 1;                            # row counter

    while ( <FILE> ) {
      # make sure we're working with a [Term] and not, for example, a
      # [Typedef] block, which also have "id: ..." lines
      if ( m/^\[Term\]/ ) {
        $is_term = 1;
      }
      # if this *is* a [Term] block and we've found an ID, store it
      if ( m/^id: (.*?)$/ and $is_term ) {
        my $id = $1;
        croak "ERROR: found an invalid ontology term ID ($1)"
          unless is_OntologyTerm($id);
        push @$term, $id;
      }
      # and if this is a [Term] and we've found a name for it, store that too
      if ( m/^name: (.*)$/ and $is_term ) {
        push @$term, $1;
        push @$chunk, $term;

        # load the current set of terms every Nth term
        if ( $n % $slice_size == 0 ) {
          try {
            $rs->populate($chunk);
          } catch {
            croak "ERROR: there was a problem loading the '$table' table: $_";
          };
          # reset the chunk array
          $chunk = [ [ 'id', 'description' ] ];
        }
        $n++;

        # reset for the next [Term]
        $term = [];
        $is_term = 0;
      }
    }
    # load the last chunk
    if ( scalar @$chunk > 1 ) {
      try {
        $rs->populate($chunk);
      } catch {
        croak "ERROR: there was a problem loading the '$table' table: $_";
      };
    }
  };

  # execute the transaction
  try {
    $self->txn_do( $txn );
  } catch {
    if ( m/Rollback failed/ ) {
      croak "ERROR: loading the ontology failed but roll back failed ($_)";
    }
    else {
      croak "ERROR: loading the ontology failed and the changes were rolled back ($_)";
    }
  };
}

#-------------------------------------------------------------------------------

=head2 add_external_resource($resource_spec}

Add a record to the C<external_resources> table to record the addition of a new
external resource. The C<$resource_spec> hash must contain the following four
required keys plus, optionally, a version:

=over 4

=item name

the name of the resource

=item source

the source of the resources, typically the canonical URL

=item retrieved_at

a L<DateTime> object giving the time that the resource file was retrieved from
the canonical source

=item checksum

an MD5 checksum for the resource file, typically generated using
L<Digest::MD5::md5sum>.

=item version

a version number for the resource, if available. Optional.

=back

=cut

sub add_external_resource {
  my ( $self, $resource_spec ) = @_;

  croak 'ERROR: one of the required fields is missing'
    unless ( defined $resource_spec->{name} and
             defined $resource_spec->{source} and
             defined $resource_spec->{retrieved_at} and
             defined $resource_spec->{checksum} );

  # format the retrieved at DateTime object
  # (see https://metacpan.org/pod/DBIx::Class::Manual::Cookbook#Formatting-DateTime-objects-in-queries)
  if ( ref $resource_spec->{retrieved_at} eq 'DateTime' ) {
    my $ra = $resource_spec->{retrieved_at};
    my $dtf = $self->storage->datetime_parser;
    my $formatted_ra = $dtf->format_datetime($ra);
    $resource_spec->{retrieved_at} = $formatted_ra;
  }

  my $resource = $self->resultset('ExternalResource')
                      ->find_or_new( $resource_spec );

  croak 'ERROR: this resource already exists'
    if $resource->in_storage;

  $resource->insert;
}

#-------------------------------------------------------------------------------

=head1 SEE ALSO

L<Bio::HICF::User>
L<Bio::Metadata::Validator>

=head1 CONTACT

path-help@sanger.ac.uk

=cut

__PACKAGE__->meta->make_immutable;

1;
