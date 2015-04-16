
package Bio::HICF::Schema::Role::Manifest;

# ABSTRACT: role carrying methods for the Manifest table

use Moose::Role;

requires qw(
  manifest_id
  checklist_id
  md5
  ticket
  created_at
  deleted_at
);

#-------------------------------------------------------------------------------

=head1 METHODS

=head2 is_deleted

Returns 1 if this sample has been deleted, 0 otherwise.

=cut

sub is_deleted {
  my $self = shift;

  return defined $self->deleted_at ? 1 : 0;
}

#-------------------------------------------------------------------------------

=head2 get_samples(?$include_deleted)

Returns the samples in this manifest in the order in which they were loaded,
i.e. the first sample will be the first one loaded and the last sample in the
list will be the most recently loaded sample.

If C<$include_deleted> is true, the method returns all rows, including those
which are flagged as deleted (have their C<deleted_at> date set). If
C<$include_deleted> is false or omitted, only live samples are returned.

If the method is called in scalar context the return value is a
L<DBIx::Class::ResultSet|ResultSet> containing all of the
L<Bio::HICF::Schema::Result::Sample|Sample>s in the manifest. If the method is
called in array context, the result is a simple list of
L<Bio::HICF::Schema::Result::Sample|Sample>s.

=cut

sub get_samples {
  my ( $self, $include_deleted ) = @_;

  my $query = $include_deleted
            ? { }
            : { 'me.deleted_at' => { '=', undef } };

  my $rs = $self->search_related(
    'samples',
    $query,
    { order_by => { -asc => ['sample_id'] } }
  );

  return wantarray ? $rs->all : $rs;
}

#-------------------------------------------------------------------------------

=head2 get_sample_ids(?$include_deleted)

Returns a list of IDs for samples in this manifest.

If C<$include_deleted> is true, the method returns the IDs for all samples,
including those which are flagged as deleted (have their C<deleted_at> date
set). If C<$include_deleted> is false or omitted, only IDs for live samples are
returned.

=cut

sub get_sample_ids {
  my ( $self, $include_deleted ) = @_;

  my @ids;
  push @ids, $_->sample_id for $self->get_samples($include_deleted);

  return @ids;
}

#-------------------------------------------------------------------------------

=head2 get_sample_values

Returns a data structure containing the values for all samples in this
manifest.

=cut

# TODO implement this

# sub get_sample_ids {
#   my ( $self, $include_deleted ) = @_;
#
#   my @ids;
#   push @ids, $_->sample_id for $self->get_samples($include_deleted);
#
#   return @ids;
# }

#-------------------------------------------------------------------------------
#- not sure we need these ------------------------------------------------------
#-------------------------------------------------------------------------------

# =head2 fields
#
# Returns a reference to a hash containing field values, keyed on field name.
#
# =cut

# sub fields {
#   my $self = shift;
#
#   my ( $values_list, $values_hash ) = $self->_get_values;
#   return $values_hash;
# }

#-------------------------------------------------------------------------------

# =head2 fields_values
#
# Returns a reference to a hash containing field values, keyed on field name.
#
# =cut

# sub field_values {
#   my $self = shift;
#
#   my ( $values_list, $values_hash ) = $self->_get_values;
#   return $values_list;
# }

#-------------------------------------------------------------------------------

# =head2 field_names
#
# Returns a list of the fields in a manifest.
#
# =cut

# sub field_names {
#   return [ qw(
#     manifest_id
#     md5
#     created_at
#   ) ];
# }

#-------------------------------------------------------------------------------
#- method modifiers ------------------------------------------------------------
#-------------------------------------------------------------------------------

# when a manifest is marked as deleted, also related rows as deleted

after 'mark_as_deleted' => sub {
  my $self = shift;

  # if we delete a manifest, we should delete all of the samples that were
  # loaded from that manifest
  my $samples_for_manifest = $self->search_related(
    'samples',
    { 'me.deleted_at' => { '=', undef } },
    {}
  );
  $_->mark_as_deleted for $samples_for_manifest->all;

  # and, provided it's not used by another manifest, we'll delete checklists
  # referenced by this manifest
  #
  # TODO decide if we really need to do this. If we do, the checklist table
  # TODO needs to have a deleted_at column re-added
};

#-------------------------------------------------------------------------------
#- private methods -------------------------------------------------------------
#-------------------------------------------------------------------------------

# returns the field values as two references, to a list of the values, in the
# order specified by "field_names", and a hash, keyed on field name
# sub _get_values {
#   my $self = shift;
#
#   my $values_list = [];
#   my $values_hash = {};
#   foreach my $field ( @{ $self->field_names } ) {
#     my $value = $self->get_column($field);
#     push @$values_list, $value;
#     $values_hash->{$field} = $value;
#   }
#
#   return ( $values_list, $values_hash );
# }

#-------------------------------------------------------------------------------

1;

