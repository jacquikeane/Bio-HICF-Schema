use utf8;
package Bio::HICF::Schema::Result::AntimicrobialResistance;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Bio::HICF::Schema::Result::AntimicrobialResistance

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

=head1 TABLE: C<antimicrobial_resistance>

=cut

__PACKAGE__->table("antimicrobial_resistance");

=head1 ACCESSORS

=head2 sample_id

  data_type: 'integer'
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
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
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

=item * L</antimicrobial_name>

=item * L</susceptibility>

=item * L</mic>

=item * L</sample_id>

=back

=cut

__PACKAGE__->set_primary_key("antimicrobial_name", "susceptibility", "mic", "sample_id");

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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-01-22 10:51:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TDk24V7DMQCPOLYWa6fQ2Q


sub get_amr_string {
  my $self = shift;

  my $amr_string = $self->antimicrobial_name . ';'
                 . $self->susceptibility . ';'
                 . $self->mic;

  $amr_string .= ';' . $self->diagnostic_centre
    if defined $self->diagnostic_centre;

  return $amr_string;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;
1;
