use utf8;
package Bio::HICF::Schema::Result::Run;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Bio::HICF::Schema::Result::Run

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

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");

=head1 TABLE: C<run>

=cut

__PACKAGE__->table("run");

=head1 ACCESSORS

=head2 run_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 sample_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 sequencing_centre

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 err_accession_number

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 global_unique_name

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 qc_status

  data_type: 'enum'
  extra: {list => ["pass","fail","unknown"]}
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
  "run_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "sample_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "sequencing_centre",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "err_accession_number",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "global_unique_name",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "qc_status",
  {
    data_type => "enum",
    extra => { list => ["pass", "fail", "unknown"] },
    is_nullable => 1,
  },
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

=item * L</run_id>

=item * L</sample_id>

=back

=cut

__PACKAGE__->set_primary_key("run_id", "sample_id");

=head1 RELATIONS

=head2 files

Type: has_many

Related object: L<Bio::HICF::Schema::Result::File>

=cut

__PACKAGE__->has_many(
  "files",
  "Bio::HICF::Schema::Result::File",
  { "foreign.run_id" => "self.run_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 sample

Type: belongs_to

Related object: L<Bio::HICF::Schema::Result::Sample>

=cut

__PACKAGE__->belongs_to(
  "sample",
  "Bio::HICF::Schema::Result::Sample",
  { sample_id => "sample_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-02-04 13:47:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8cBZHI2f8qmDibEw4gFn0w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
