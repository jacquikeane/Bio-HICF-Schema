use utf8;
package Bio::HICF::Schema::Result::AntimicrobialResistance;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Bio::HICF::Schema::Result::AntimicrobialResistance

=head1 DESCRIPTION

Stores information about the antimicrobial resistance tests for a given sample. The antimicrobial compound must exist in the look-up table.

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

=head1 TABLE: C<antimicrobial_resistance>

=cut

__PACKAGE__->table("antimicrobial_resistance");

=head1 ACCESSORS

=head2 sample_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 antimicrobial_name

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 100

=head2 susceptibility

  data_type: 'enum'
  extra: {list => ["S","I","R"]}
  is_nullable: 0

Susceptibility to the antimicrobial. One of Susceptible, Intermediate or Resistant

=head2 mic

  data_type: 'varchar'
  is_nullable: 0
  size: 45

Minimum inhibitory concentration

=head2 equality

  data_type: 'enum'
  default_value: 'eq'
  extra: {list => ["le","lt","eq","gt","ge"]}
  is_nullable: 0

=head2 diagnostic_centre

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
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "antimicrobial_name",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 100 },
  "susceptibility",
  {
    data_type => "enum",
    extra => { list => ["S", "I", "R"] },
    is_nullable => 0,
  },
  "mic",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "equality",
  {
    data_type => "enum",
    default_value => "eq",
    extra => { list => ["le", "lt", "eq", "gt", "ge"] },
    is_nullable => 0,
  },
  "diagnostic_centre",
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

=item * L</antimicrobial_name>

=item * L</susceptibility>

=item * L</mic>

=item * L</equality>

=back

=cut

__PACKAGE__->set_primary_key(
  "sample_id",
  "antimicrobial_name",
  "susceptibility",
  "mic",
  "equality",
);

=head1 RELATIONS

=head2 antimicrobial_name

Type: belongs_to

Related object: L<Bio::HICF::Schema::Result::Antimicrobial>

=cut

__PACKAGE__->belongs_to(
  "antimicrobial_name",
  "Bio::HICF::Schema::Result::Antimicrobial",
  { name => "antimicrobial_name" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
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

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Bio::HICF::Schema::Role::AntimicrobialResistance>

=back

=cut


with 'Bio::HICF::Schema::Role::AntimicrobialResistance';


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-04-09 15:05:20
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Ydid6VrdV5phsHfw0NvZ9A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
