use utf8;
package Bio::HICF::Schema::Result::Antimicrobial;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Bio::HICF::Schema::Result::Antimicrobial - A curated list of antimicrobial compounds.

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

=head1 TABLE: C<antimicrobial>

=cut

__PACKAGE__->table("antimicrobial");

=head1 ACCESSORS

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

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
  "name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
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

=item * L</name>

=back

=cut

__PACKAGE__->set_primary_key("name");

=head1 RELATIONS

=head2 antimicrobial_resistances

Type: has_many

Related object: L<Bio::HICF::Schema::Result::AntimicrobialResistance>

=cut

__PACKAGE__->has_many(
  "antimicrobial_resistances",
  "Bio::HICF::Schema::Result::AntimicrobialResistance",
  { "foreign.antimicrobial_name" => "self.name" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Bio::HICF::Schema::Role::Undeletable>

=back

=cut


with 'Bio::HICF::Schema::Role::Undeletable';


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-04-13 15:18:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:L75r9s/OrLPXxPOldCPqVQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
