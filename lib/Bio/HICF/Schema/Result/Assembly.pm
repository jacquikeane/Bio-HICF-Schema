use utf8;
package Bio::HICF::Schema::Result::Assembly;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Bio::HICF::Schema::Result::Assembly

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

=head1 TABLE: C<assembly>

=cut

__PACKAGE__->table("assembly");

=head1 ACCESSORS

=head2 assembly_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 sample_accession

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 20

=head2 type

  data_type: 'enum'
  extra: {list => ["ERS"]}
  is_nullable: 1

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
  "assembly_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "sample_accession",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 20 },
  "type",
  { data_type => "enum", extra => { list => ["ERS"] }, is_nullable => 1 },
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

=item * L</assembly_id>

=back

=cut

__PACKAGE__->set_primary_key("assembly_id");

=head1 RELATIONS

=head2 files

Type: has_many

Related object: L<Bio::HICF::Schema::Result::File>

=cut

__PACKAGE__->has_many(
  "files",
  "Bio::HICF::Schema::Result::File",
  { "foreign.assembly_id" => "self.assembly_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 sample_accession

Type: belongs_to

Related object: L<Bio::HICF::Schema::Result::Sample>

=cut

__PACKAGE__->belongs_to(
  "sample_accession",
  "Bio::HICF::Schema::Result::Sample",
  { sample_accession => "sample_accession" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Bio::HICF::Schema::Role::Assembly>

=item * L<Bio::HICF::Schema::Role::Undeletable>

=back

=cut


with 'Bio::HICF::Schema::Role::Assembly', 'Bio::HICF::Schema::Role::Undeletable';


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-04-14 10:03:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RxDVodB4q8Hricl8MdYSQw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
