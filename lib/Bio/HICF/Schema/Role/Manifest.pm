
package Bio::HICF::Schema::Role::Manifest;

# ABSTRACT: role carrying methods for the Manifest table

use Moose::Role;

requires qw(
  manifest_id
  config_id
  md5
  ticket
  created_at
  updated_at
  deleted_at
);

#-------------------------------------------------------------------------------

=head1 METHODS

=head2 fields

Returns a reference to a hash containing field values, keyed on field name.

=cut

sub fields {
  my $self = shift;

  my ( $values_list, $values_hash ) = $self->_get_values;
  return $values_hash;
}

#-------------------------------------------------------------------------------

=head2 fields_values

Returns a reference to a hash containing field values, keyed on field name.

=cut

sub field_values {
  my $self = shift;

  my ( $values_list, $values_hash ) = $self->_get_values;
  return $values_list;
}

#-------------------------------------------------------------------------------

=head2 field_names

Returns a list of the fields in a manifest.

=cut

sub field_names {
  return [ qw(
    manifest_id
    md5
    created_at
  ) ];
}

#-------------------------------------------------------------------------------
#- private methods -------------------------------------------------------------
#-------------------------------------------------------------------------------

# returns the field values as two references, to a list of the values, in the
# order specified by "field_names", and a hash, keyed on field name
sub _get_values {
  my $self = shift;

  my $values_list = [];
  my $values_hash = {};
  foreach my $field ( @{ $self->field_names } ) {
    my $value = $self->get_column($field);
    push @$values_list, $value;
    $values_hash->{$field} = $value;
  }

  return ( $values_list, $values_hash );
}

#-------------------------------------------------------------------------------

1;

