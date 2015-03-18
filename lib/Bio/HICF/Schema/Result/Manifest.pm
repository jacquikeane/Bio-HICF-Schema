use utf8;
package Bio::HICF::Schema::Result::Manifest;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Bio::HICF::Schema::Result::Manifest - Stores details of a manifest containing multiple samples.

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=item * L<DBIx::Class::PassphraseColumn>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "PassphraseColumn");

=head1 TABLE: C<manifest>

=cut

__PACKAGE__->table("manifest");

=head1 ACCESSORS

=head2 manifest_id

  data_type: 'char'
  is_nullable: 0
  size: 36

A UUID that uniquely identifies the manifest.

=head2 config_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 md5

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 ticket

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 created_at

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0
  set_on_create: 1

=head2 updated_at

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1
  set_on_update: 1

=head2 deleted_at

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "manifest_id",
  { data_type => "char", is_nullable => 0, size => 36 },
  "config_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "md5",
  { data_type => "char", is_nullable => 0, size => 32 },
  "ticket",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "created_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
    set_on_create => 1,
  },
  "updated_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
    set_on_update => 1,
  },
  "deleted_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</manifest_id>

=back

=cut

__PACKAGE__->set_primary_key("manifest_id");

=head1 RELATIONS

=head2 config

Type: belongs_to

Related object: L<Bio::HICF::Schema::Result::ManifestConfig>

=cut

__PACKAGE__->belongs_to(
  "config",
  "Bio::HICF::Schema::Result::ManifestConfig",
  { config_id => "config_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 samples

Type: has_many

Related object: L<Bio::HICF::Schema::Result::Sample>

=cut

__PACKAGE__->has_many(
  "samples",
  "Bio::HICF::Schema::Result::Sample",
  { "foreign.manifest_id" => "self.manifest_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-02-24 13:54:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Eq9YVxkxtzn0EjabF/KccA

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

__PACKAGE__->meta->make_immutable;
1;
