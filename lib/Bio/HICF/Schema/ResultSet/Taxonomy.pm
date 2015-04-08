use utf8;
package Bio::HICF::Schema::ResultSet::Taxonomy;

use Moose;
use MooseX::NonMoose;
use MooseX::Params::Validate;
use Carp qw ( croak );
use Try::Tiny;

extends 'DBIx::Class::ResultSet';

sub BUILDARGS { $_[2] }
# see https://metacpan.org/pod/DBIx::Class::ResultSet#ResultSet-subclassing-with-Moose-and-similar-constructor-providers

#-------------------------------------------------------------------------------

# ABSTRACT: resultset for the taxonomy table

=head1 METHODS

=head2 load($tree,$?slice_size)

load the given tree into the taxonomy table. Requires a reference to a
L<Bio::Metadata::TaxTree> object containing the tree data. The rows
representing the tree nodes are loaded in chunks of 1000 rows at a time by
default. This "slice size" can be overridden with the optional C<$slice_size>
parameter.

B<Note> that the C<taxonomy> table will be truncated before loading.

Throws DBIC exceptions if loading fails. If possible, the entire transaction,
including the table truncation and any subsequent loading, will be rolled back.
If roll back fails, the error message will contain the string C<roll back
failed>.

=cut

sub load {
  my ( $self, $tree, $slice_size ) = @_;

  croak 'ERROR: not a Bio::Metadata::Tree object'
    unless ref $tree eq 'Bio::Metadata::TaxTree';

  $slice_size ||= 1000;

  # get a simple list of column values for all of the nodes in the tree
  my $nodes = $tree->get_node_values;

  # wrap this whole operation in a transaction
  my $txn = sub {

    # empty the table before we start
    $self->delete;

    # since the number of rows to insert will be very large, we'll use the fast
    # insertion routines in DBIC and we'll load in chunks
    for ( my $i = 0; $i < scalar @$nodes; $i = $i + $slice_size ) {

      # the column names must be the first row
      my $rows = [
        [ qw( tax_id name lft rgt parent_tax_id ) ]
      ];

      # work out the bounds of the array slice
      my $from = $i,
      my $to   = $i + $slice_size - 1;

      # add the slice to the list of rows, grepping out undefined rows (needed
      # to avoid insertion errors when the last slice isn't full)
      push @$rows, grep defined, @$nodes[$from..$to];

      $self->populate($rows);
    }

  };

  # execute the transaction
  try {
    $self->result_source->schema->txn_do( $txn );
  } catch {
    if ( m/Rollback failed/ ) {
      croak "ERROR: loading the tax tree failed but roll back failed: $_";
    }
    else {
      croak "ERROR: loading the tax tree failed and the changes were rolled back: $_";
    }
  };
}
#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;
