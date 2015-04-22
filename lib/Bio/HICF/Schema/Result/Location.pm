use utf8;
package Bio::HICF::Schema::Result::Location;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Bio::HICF::Schema::Result::Location

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

	

=head2 lat

  data_type: 'float'
  is_nullable: 1

=head2 lng

  data_type: 'float'
  is_nullable: 1

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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-04-22 12:29:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:X13sJR/jxDTFN28KQXYOiQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
