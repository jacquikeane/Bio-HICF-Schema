use utf8;
package Bio::HICF::Schema::Role::Undeletable;

# ABSTRACT: role overriding the default "delete" method

use Moose::Role;
use DateTime;

requires qw(
  deleted_at
);

#-------------------------------------------------------------------------------

=head1 DESCRIPTION

There are several tables which could require data to be deleted, but rather
than entirely remove data, we want to update the C<deleted_at> field for each
row, so that we can track all data, live and historical. This
L<Moose::Role|Role> provides a L<delete> method which "deletes" a row by
updating the C<deleted_at> field.

=head1 METHODS

=head2 mark_as_deleted

Marks this row as deleted by setting C<deleted_at> to the current time.
Returns immediately if a row already has C<deleted_at>. No return value.

=cut

sub mark_as_deleted {
  my $self = shift;
  return if $self->deleted_at;
  $self->update( { deleted_at => DateTime->now } );
}

#-------------------------------------------------------------------------------

=head2 delete

Alias for L<delete>.

=cut

sub delete { shift->mark_as_deleted }

#-------------------------------------------------------------------------------
1;

