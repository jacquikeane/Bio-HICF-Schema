use utf8;
package Bio::HICF::Schema::Result::Sample;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Bio::HICF::Schema::Result::Sample - Details of a single sample

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

Unique ID for the sample

=head2 manifest_id

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 0
  size: 36

The ID of the manifest from which the sample was loaded

=head2 raw_data_accession

  data_type: 'varchar'
  is_nullable: 0
  size: 45

The accession for the raw sequencing data corresponding to this sample

=head2 sample_accession

  data_type: 'varchar'
  is_nullable: 0
  size: 20

The accession for this sample in the sequence repository where is has been deposited

=head2 sample_description

  data_type: 'tinytext'
  is_nullable: 1

A free-text description of the sample

=head2 collected_at

  data_type: 'enum'
  extra: {list => ["WTSI","UCL","OXFORD"]}
  is_nullable: 1

The site at which the sample was collected. Must be one of `WTSI`, `UCL`, `OXFORD`.

=head2 tax_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

The taxonomy ID of the organism represented by the sample, from the NCBI taxonomy tree


=head2 scientific_name

  data_type: 'varchar'
  is_nullable: 1
  size: 200

The scientific name of the organism represented by the sample, from the NCBI taxonomy tree

=head2 collected_by

  data_type: 'varchar'
  is_nullable: 1
  size: 200

Free-text description of the person or persons who obtained the sample

=head2 source

  data_type: 'varchar'
  is_nullable: 1
  size: 45

A free-text description of the source of the sample

=head2 collection_date

  accessor: '_collection_date'
  data_type: 'varchar'
  is_nullable: 0
  size: 50

Date/time at which the sample was collected, given as epoch seconds

=head2 location

  accessor: '_location'
  data_type: 'varchar'
  is_nullable: 0
  size: 50

The location at which the sample was collected, given as a term from the gazetteer ontology.

=head2 host_associated

  accessor: '_host_associated'
  data_type: 'varchar'
  is_nullable: 0
  size: 50

Boolean indicating that the sample organism is associated with a host

=head2 specific_host

  accessor: '_specific_host'
  data_type: 'varchar'
  is_nullable: 1
  size: 200

Scientific name of the host organism, If the sample organism is host associated

=head2 host_disease_status

  accessor: '_host_disease_status'
  data_type: 'varchar'
  is_nullable: 1
  size: 50

Disease status of the host organism. Must be one of `diseased`, `healthy`, `carriage`.

=head2 host_isolation_source

  accessor: '_host_isolation_source'
  data_type: 'varchar'
  is_nullable: 1
  size: 50

Name of the host tissue or organ that was sampled

=head2 patient_location

  accessor: '_patient_location'
  data_type: 'varchar'
  is_nullable: 1
  size: 50

Describes the health care situation of a human host when the sample was taken. Must be either `inpatient` or `community`.

=head2 isolation_source

  accessor: '_isolation_source'
  data_type: 'varchar'
  is_nullable: 1
  size: 50

Term from the EnvO ontology describing the physical environment from which the sample was obtained

=head2 serovar

  data_type: 'text'
  is_nullable: 1

Serological variety of the sample organism

=head2 other_classification

  data_type: 'text'
  is_nullable: 1

Classification term(s) for the sample organism

=head2 strain

  data_type: 'text'
  is_nullable: 1

Name of the strain of the sample organism

=head2 isolate

  data_type: 'text'
  is_nullable: 1

Name of the isolate from which the sample was obtained

=head2 withdrawn

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 created_at

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0
  set_on_create: 1

Date/time at which the sample was added to the database

=head2 deleted_at

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

Date/time at which the sample was flagged as deleted in the database

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
    data_type => "varchar",
    is_nullable => 0,
    size => 50,
  },
  "location",
  {
    accessor => "_location",
    data_type => "varchar",
    is_nullable => 0,
    size => 50,
  },
  "host_associated",
  {
    accessor => "_host_associated",
    data_type => "varchar",
    is_nullable => 0,
    size => 50,
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
    accessor => "_host_disease_status",
    data_type => "varchar",
    is_nullable => 1,
    size => 50,
  },
  "host_isolation_source",
  {
    accessor => "_host_isolation_source",
    data_type => "varchar",
    is_nullable => 1,
    size => 50,
  },
  "patient_location",
  {
    accessor => "_patient_location",
    data_type => "varchar",
    is_nullable => 1,
    size => 50,
  },
  "isolation_source",
  {
    accessor => "_isolation_source",
    data_type => "varchar",
    is_nullable => 1,
    size => 50,
  },
  "serovar",
  { data_type => "text", is_nullable => 1 },
  "other_classification",
  { data_type => "text", is_nullable => 1 },
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
  { "foreign.sample_accession" => "self.sample_accession" },
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

=item * L<Bio::HICF::Schema::Role::Undeletable>

=back

=cut


with 'Bio::HICF::Schema::Role::Sample', 'Bio::HICF::Schema::Role::Undeletable';


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-04-23 14:38:51
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Z6nG+MEYr5IhVrXY2Rt29A

__PACKAGE__->add_unique_constraint(
  sample_uc => [ qw( manifest_id raw_data_accession sample_accession ) ]
);

__PACKAGE__->meta->make_immutable;
1;

