use utf8;
package Bio::HICF::Schema::Result::Manifest;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Bio::HICF::Schema::Result::Manifest

=head1 DESCRIPTION

Details of a specific manifest

A manifest is a collection of multiple samples. Every sample must be loaded as part of a manifest and each manifest must be assigned a unique identifier.

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

The ID of the checklist configuration that was used to validate this manifest

=head2 md5

  data_type: 'char'
  is_nullable: 0
  size: 32

The MD5 checksum for the file from which the manifest was loaded

=head2 ticket

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

If the manifest was provided in a request tracked ticket, the ID of the RT ticket may be given here

=head2 created_at

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0
  set_on_create: 1

Date/time at which the manifest was added to the database

=head2 deleted_at

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

Date/time at which the manifest was flagged as deleted in the database

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

=item * L<Bio::HICF::Schema::Role::Undeletable>

=back

=cut


with 'Bio::HICF::Schema::Role::Manifest', 'Bio::HICF::Schema::Role::Undeletable';


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-04-23 14:38:51
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:v9D7tDYB2TPwamTyzqBZsA


__PACKAGE__->meta->make_immutable;
1;
