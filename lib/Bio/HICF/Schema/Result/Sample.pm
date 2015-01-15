use utf8;
package Bio::HICF::Schema::Result::Sample;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Bio::HICF::Schema::Result::Sample

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

=head1 TABLE: C<sample>

=cut

__PACKAGE__->table("sample");

=head1 ACCESSORS

=head2 sample_id

  data_type: 'integer'
  is_nullable: 0

=head2 raw_data_accession

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=head2 sample_accession

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=head2 sample_description

  data_type: 'tinytext'
  is_nullable: 1

=head2 ncbi_taxid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 scientific_name

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 collected_by

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 source

  data_type: 'enum'
  extra: {list => ["WTSI","UCL","OXFORD"]}
  is_nullable: 1

=head2 collection_date

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 location

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 12

=head2 host_associated

  data_type: 'tinyint'
  is_nullable: 0

=head2 specific_host

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 host_disease_status

  data_type: 'enum'
  extra: {list => ["healthy","diseased","carriage"]}
  is_nullable: 1

=head2 host_isolation_source

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 11

=head2 isolation_source

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 1
  size: 10

=head2 serovar

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 other_classification

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 strain

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 isolate

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 withdrawn

  data_type: 'varchar'
  is_nullable: 1
  size: 45

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
  "sample_id",
  { data_type => "integer", is_nullable => 0 },
  "raw_data_accession",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "sample_accession",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "sample_description",
  { data_type => "tinytext", is_nullable => 1 },
  "ncbi_taxid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "scientific_name",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "collected_by",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "source",
  {
    data_type => "enum",
    extra => { list => ["WTSI", "UCL", "OXFORD"] },
    is_nullable => 1,
  },
  "collection_date",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "location",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 12 },
  "host_associated",
  { data_type => "tinyint", is_nullable => 0 },
  "specific_host",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "host_disease_status",
  {
    data_type => "enum",
    extra => { list => ["healthy", "diseased", "carriage"] },
    is_nullable => 1,
  },
  "host_isolation_source",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 11 },
  "isolation_source",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 1, size => 10 },
  "serovar",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "other_classification",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "strain",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "isolate",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "withdrawn",
  { data_type => "varchar", is_nullable => 1, size => 45 },
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

=item * L</sample_id>

=back

=cut

__PACKAGE__->set_primary_key("sample_id");

=head1 RELATIONS

=head2 antimicrobial_resistances

Type: has_many

Related object: L<Bio::HICF::Schema::Result::AntimicrobialResistance>

=cut

__PACKAGE__->has_many(
  "antimicrobial_resistances",
  "Bio::HICF::Schema::Result::AntimicrobialResistance",
  { "foreign.sample_id" => "self.sample_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 host_isolation_source

Type: belongs_to

Related object: L<Bio::HICF::Schema::Result::Brenda>

=cut

__PACKAGE__->belongs_to(
  "host_isolation_source",
  "Bio::HICF::Schema::Result::Brenda",
  { brenda_id => "host_isolation_source" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 isolation_source

Type: belongs_to

Related object: L<Bio::HICF::Schema::Result::Envo>

=cut

__PACKAGE__->belongs_to(
  "isolation_source",
  "Bio::HICF::Schema::Result::Envo",
  { envo_id => "isolation_source" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 location

Type: belongs_to

Related object: L<Bio::HICF::Schema::Result::Gazetteer>

=cut

__PACKAGE__->belongs_to(
  "location",
  "Bio::HICF::Schema::Result::Gazetteer",
  { gaz_id => "location" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 ncbi_taxid

Type: belongs_to

Related object: L<Bio::HICF::Schema::Result::Taxonomy>

=cut

__PACKAGE__->belongs_to(
  "ncbi_taxid",
  "Bio::HICF::Schema::Result::Taxonomy",
  { ncbi_taxid => "ncbi_taxid" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 runs

Type: has_many

Related object: L<Bio::HICF::Schema::Result::Run>

=cut

__PACKAGE__->has_many(
  "runs",
  "Bio::HICF::Schema::Result::Run",
  { "foreign.sample_id" => "self.sample_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-01-14 16:23:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GgzByJzytLAfcPz6IwzV2A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
