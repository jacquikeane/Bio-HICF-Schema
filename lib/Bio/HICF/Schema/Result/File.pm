use utf8;
package Bio::HICF::Schema::Result::File;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Bio::HICF::Schema::Result::File

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

=head1 TABLE: C<file>

=cut

__PACKAGE__->table("file");

=head1 ACCESSORS

=head2 file_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 assembly_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 version

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 path

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=head2 md5

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 created_at

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0
  set_on_create: 1

=head2 deleted_at

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "file_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "assembly_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "version",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "path",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "md5",
  { data_type => "char", is_nullable => 0, size => 32 },
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

=item * L</file_id>

=back

=cut

__PACKAGE__->set_primary_key("file_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<file_version_UNIQUE>

=over 4

=item * L</version>

=item * L</assembly_id>

=back

=cut

__PACKAGE__->add_unique_constraint("file_version_UNIQUE", ["version", "assembly_id"]);

=head2 C<md5_UNIQUE>

=over 4

=item * L</md5>

=back

=cut

__PACKAGE__->add_unique_constraint("md5_UNIQUE", ["md5"]);

=head2 C<path_UNIQUE>

=over 4

=item * L</path>

=back

=cut

__PACKAGE__->add_unique_constraint("path_UNIQUE", ["path"]);

=head1 RELATIONS

=head2 assembly

Type: belongs_to

Related object: L<Bio::HICF::Schema::Result::Assembly>

=cut

__PACKAGE__->belongs_to(
  "assembly",
  "Bio::HICF::Schema::Result::Assembly",
  { assembly_id => "assembly_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Bio::HICF::Schema::Role::Undeletable>

=back

=cut


with 'Bio::HICF::Schema::Role::Undeletable';


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-04-14 09:35:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RPVMfLBPP465ko2MJ9jFNw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
