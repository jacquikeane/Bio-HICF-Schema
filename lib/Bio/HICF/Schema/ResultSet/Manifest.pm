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

Loads the sample data in a L<Bio::Metadata::Manifest>. Returns a list of the
sample IDs for the newly inserted rows.

The database changes are made inside a transaction (see
L<DBIx::Class::Storage#txn_do>). If there is a problem during loading an
exception is throw and we try to roll back any database changes that have been
made. If the roll back fails, the error message will include the phrase "roll
back failed".

=cut

sub load {
  my ( $self, $manifest ) = @_;

  croak 'ERROR: not a Bio::Metadata::Manifest'
    unless ref $manifest eq 'Bio::Metadata::Manifest';

  croak 'ERROR: the data in the manifest are not valid'
    unless $self->validator->validate($manifest);

  my $schema = $self->result_source->schema;

  # build a transaction
  my @row_ids;
  my $txn = sub {

    # add a row to the manifest table
    my $rs = $self->find_or_create(
      {
        manifest_id => $manifest->uuid,
        md5         => $manifest->md5,
        config      => { config => $manifest->config->config_string }
      },
      { key => 'primary' }
    );

    # load the sample rows
    my $field_names = $manifest->field_names;

    foreach my $row ( $manifest->all_rows ) {

      # zip the field names and values together to form a hash...
      my %upload = mesh @$field_names, @$row;

      # ... add the manifest ID...
      $upload{manifest_id} = $manifest->uuid;

      # ... and pass that hash to the ResultSet to load
      push @row_ids, $schema->resultset('Sample')->load( \%upload );
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

  return @row_ids;
}

#-------------------------------------------------------------------------------
#- private methods -------------------------------------------------------------
#-------------------------------------------------------------------------------

# none yet

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;
