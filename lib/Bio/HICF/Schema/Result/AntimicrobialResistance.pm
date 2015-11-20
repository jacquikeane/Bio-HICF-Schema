use utf8;
package Bio::HICF::Schema::Result::AntimicrobialResistance;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Bio::HICF::Schema::Result::AntimicrobialResistance - Antimicrobial resistance tests for a given sample

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

Susceptibility to the antimicrobial. One of `Susceptible`, `Intermediate` or `Resistant`

=head2 mic

  data_type: 'varchar'
  is_nullable: 1
  size: 45

Minimum inhibitory concentration

=head2 equality

  data_type: 'enum'
  default_value: 'eq'
  extra: {list => ["le","lt","eq","gt","ge"]}
  is_nullable: 0

The susceptibility of the tested sample to a given antimicrobial may be given in terms of a lower or upper limit, e.g. sample was found susceptible to compound at an MIC of less than 4 microgrammes/millilitre. This field specifies the equality. Must be one of `le` (<=), `lt` (<), `eq` (=), `gt` (>), `ge` (>=). The default is `eq`.

=head2 method

  data_type: 'varchar'
  is_nullable: 1
  size: 45

The method used for antimicrobial testing

=head2 created_at

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0
  set_on_create: 1

Date/time at which the antimicrobial test result was added to the database

=head2 deleted_at

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

Date/time at which the antimicrobial test result was flagged as deleted in the database

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
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "equality",
  {
    data_type => "enum",
    default_value => "eq",
    extra => { list => ["le", "lt", "eq", "gt", "ge"] },
    is_nullable => 0,
  },
  "method",
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

=item * L</antimicrobial_name>

=item * L</susceptibility>

=back

=cut

__PACKAGE__->set_primary_key(
  "sample_id",
  "antimicrobial_name",
  "susceptibility",
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

=item * L<Bio::HICF::Schema::Role::Undeletable>

=back

=cut


with 'Bio::HICF::Schema::Role::AntimicrobialResistance', 'Bio::HICF::Schema::Role::Undeletable';

# NOTE the automatically generated code above has been altered, so
# NOTE re-generating the class using the loader will no longer work
#
### Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-04-23 14:38:51
### DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qwSOs5dye63ZzXY0Y1TKgg


__PACKAGE__->meta->make_immutable;
1;
