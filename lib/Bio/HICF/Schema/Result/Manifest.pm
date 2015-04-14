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

=head2 checklist_id

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

=head2 deleted_at

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "manifest_id",
  { data_type => "char", is_nullable => 0, size => 36 },
  "checklist_id",
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

=head2 checklist

Type: belongs_to

Related object: L<Bio::HICF::Schema::Result::Checklist>

=cut

__PACKAGE__->belongs_to(
  "checklist",
  "Bio::HICF::Schema::Result::Checklist",
  { checklist_id => "checklist_id" },
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

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Bio::HICF::Schema::Role::Manifest>

=back

=cut


with 'Bio::HICF::Schema::Role::Manifest';


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-04-13 15:35:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:J5GlMxd1Cc5slMbYwMovbQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
