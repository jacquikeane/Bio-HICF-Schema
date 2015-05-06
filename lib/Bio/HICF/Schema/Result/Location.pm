use utf8;
package Bio::HICF::Schema::Result::Location;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Bio::HICF::Schema::Result::Location - Geographical location for terms in the gazetteer ontology

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

=head1 TABLE: C<location>

=cut

__PACKAGE__->table("location");

=head1 ACCESSORS

=head2 gaz_term

  data_type: 'varchar'
  is_nullable: 0
  size: 50

The gazetteer ontology term

=head2 lat

  data_type: 'float'
  is_nullable: 1

Latitude. The north-south position, in degrees, of the location

=head2 lng

  data_type: 'float'
  is_nullable: 1

Longitude. The east-west position, in degrees, of the location

=cut

__PACKAGE__->add_columns(
  "gaz_term",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "lat",
  { data_type => "float", is_nullable => 1 },
  "lng",
  { data_type => "float", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</gaz_term>

=back

=cut

__PACKAGE__->set_primary_key("gaz_term");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-04-23 14:38:51
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6OMdnzhF2OeSgegnsIY9VA


__PACKAGE__->meta->make_immutable;
1;
