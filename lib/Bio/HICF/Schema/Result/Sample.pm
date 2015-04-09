use utf8;
package Bio::HICF::Schema::Result::Sample;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Bio::HICF::Schema::Result::Sample

=head1 DESCRIPTION

Stores a single sample from a manifest. Every sample must belong to a manifest.

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

=head1 TABLE: C<sample>

=cut

__PACKAGE__->table("sample");

=head1 ACCESSORS

=head2 sample_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 manifest_id

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 0
  size: 36

=head2 raw_data_accession

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=head2 sample_accession

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=head2 sample_description

  data_type: 'tinytext'
  is_nullable: 1

=head2 collected_at

  data_type: 'enum'
  extra: {list => ["WTSI","UCL","OXFORD"]}
  is_nullable: 1

=head2 tax_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 scientific_name

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=head2 collected_by

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=head2 source

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 collection_date

  accessor: '_collection_date'
  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 location

  accessor: '_location'
  data_type: 'varchar'
  is_nullable: 0
  size: 15

=head2 host_associated

  accessor: '_host_associated'
  data_type: 'tinyint'
  is_nullable: 0

=head2 specific_host

  accessor: '_specific_host'
  data_type: 'varchar'
  is_nullable: 1
  size: 200

=head2 host_disease_status

  accessor: '_host_disease_status'
  data_type: 'enum'
  extra: {list => ["healthy","diseased","carriage"]}
  is_nullable: 1

=head2 host_isolation_source

  accessor: '_host_isolation_source'
  data_type: 'varchar'
  is_nullable: 1
  size: 15

=head2 patient_location

  accessor: '_patient_location'
  data_type: 'enum'
  extra: {list => ["inpatient","community"]}
  is_nullable: 1

=head2 isolation_source

  accessor: '_isolation_source'
  data_type: 'varchar'
  is_nullable: 1
  size: 15

=head2 serovar

  accessor: '_serovar'
  data_type: 'text'
  is_nullable: 1

=head2 other_classification

  accessor: '_other_classification'
  data_type: 'text'
  is_nullable: 1

=head2 strain

  data_type: 'text'
  is_nullable: 1

=head2 isolate

  data_type: 'text'
  is_nullable: 1

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
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "manifest_id",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 36 },
  "raw_data_accession",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "sample_accession",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "sample_description",
  { data_type => "tinytext", is_nullable => 1 },
  "collected_at",
  {
    data_type => "enum",
    extra => { list => ["WTSI", "UCL", "OXFORD"] },
    is_nullable => 1,
  },
  "tax_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "scientific_name",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "collected_by",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "source",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "collection_date",
  {
    accessor => "_collection_date",
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "location",
  {
    accessor => "_location",
    data_type => "varchar",
    is_nullable => 0,
    size => 15,
  },
  "host_associated",
  {
    accessor    => "_host_associated",
    data_type   => "tinyint",
    is_nullable => 0,
  },
  "specific_host",
  {
    accessor => "_specific_host",
    data_type => "varchar",
    is_nullable => 1,
    size => 200,
  },
  "host_disease_status",
  {
    accessor    => "_host_disease_status",
    data_type   => "enum",
    extra       => { list => ["healthy", "diseased", "carriage"] },
    is_nullable => 1,
  },
  "host_isolation_source",
  {
    accessor => "_host_isolation_source",
    data_type => "varchar",
    is_nullable => 1,
    size => 15,
  },
  "patient_location",
  {
    accessor    => "_patient_location",
    data_type   => "enum",
    extra       => { list => ["inpatient", "community"] },
    is_nullable => 1,
  },
  "isolation_source",
  {
    accessor => "_isolation_source",
    data_type => "varchar",
    is_nullable => 1,
    size => 15,
  },
  "serovar",
  { accessor => "_serovar", data_type => "text", is_nullable => 1 },
  "other_classification",
  {
    accessor    => "_other_classification",
    data_type   => "text",
    is_nullable => 1,
  },
  "strain",
  { data_type => "text", is_nullable => 1 },
  "isolate",
  { data_type => "text", is_nullable => 1 },
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

=head2 assemblies

Type: has_many

Related object: L<Bio::HICF::Schema::Result::Assembly>

=cut

__PACKAGE__->has_many(
  "assemblies",
  "Bio::HICF::Schema::Result::Assembly",
  { "foreign.accession" => "self.sample_accession" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 manifest

Type: belongs_to

Related object: L<Bio::HICF::Schema::Result::Manifest>

=cut

__PACKAGE__->belongs_to(
  "manifest",
  "Bio::HICF::Schema::Result::Manifest",
  { manifest_id => "manifest_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Bio::HICF::Schema::Role::Sample>

=back

=cut


with 'Bio::HICF::Schema::Role::Sample';


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-04-09 14:39:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TVUaE9royaWqADUytwJJRQ

__PACKAGE__->add_unique_constraint(
  sample_uc => [ qw( manifest_id raw_data_accession sample_accession ) ]
);

__PACKAGE__->meta->make_immutable;

1;

