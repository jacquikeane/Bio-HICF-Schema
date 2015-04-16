use utf8;
package Bio::HICF::Schema::ResultSet::Manifest;

use Moose;
use MooseX::NonMoose;
use MooseX::Params::Validate;
use Carp qw ( croak );
use Try::Tiny;
use List::MoreUtils qw( mesh );

use Bio::Metadata::Manifest;
use Bio::Metadata::Validator;

extends 'DBIx::Class::ResultSet';

sub BUILDARGS { $_[2] }
# see https://metacpan.org/pod/DBIx::Class::ResultSet#ResultSet-subclassing-with-Moose-and-similar-constructor-providers

#-------------------------------------------------------------------------------

# ABSTRACT: resultset for the manifest table

=head1 METHODS

=head2 ATTRIBUTES

=cut

has 'validator' => (
  is      => 'ro',
  isa     => 'Bio::Metadata::Validator',
  default => sub { new Bio::Metadata::Validator },
);

#-------------------------------------------------------------------------------

=head2 load($manifest)

Loads the sample data in a L<Bio::Metadata::Manifest>. Returns the resulting
L<Bio::HICF::Schema::Result::Manifest>.

The database changes are made inside a transaction (see
L<DBIx::Class::Storage#txn_do>). If there is a problem during loading an
exception is thrown and we try to roll back any database changes that have
already been made. If the roll back fails, the error message will include the
phrase "roll back failed".

=cut

sub load {
  my ( $self, $manifest_object ) = @_;

  croak 'ERROR: not a Bio::Metadata::Manifest'
    unless ref $manifest_object eq 'Bio::Metadata::Manifest';

  croak 'ERROR: the data in the manifest are not valid'
    unless $self->validator->validate($manifest_object);

  my $schema = $self->result_source->schema;

  # build a transaction
  my @row_ids;
  my $manifest_row;
  my $txn = sub {

    # add a row to the manifest table
    $manifest_row = $self->find_or_create(
      {
        manifest_id => $manifest_object->uuid,
        md5         => $manifest_object->md5,
        checklist   => { config => $manifest_object->checklist->config_string }
      },
      { key => 'primary' }
    );

    # load the sample rows
    my $field_names = $manifest_object->field_names;

    foreach my $row ( $manifest_object->all_rows ) {

      # zip the field names and values together to form a hash...
      my %upload = mesh @$field_names, @$row;

      # ... add the manifest ID...
      $upload{manifest_id} = $manifest_object->uuid;

      # ... and pass that hash to the ResultSet to load
      push @row_ids, $schema->resultset('Sample')->load(\%upload);
    }

  };

  # run the transaction
  try {
    $schema->txn_do($txn);
  }
  catch {
    if (m/Rollback failed/) {
      croak "ERROR: there was an error when loading the manifest but roll back failed: $_";
    }
    else {
      croak "ERROR: there was an error when loading the manifest; changes have been rolled back: $_";
    }
  };

  return $manifest_row;

  # TODO we could modify the Bio::Metadata::Manifest class to store the list
  # TODO of loaded sample IDs
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;
