use utf8;
package Bio::HICF::Schema::Result::Gazetteer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Bio::HICF::Schema::Result::Gazetteer

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

=head1 TABLE: C<gazetteer>

=cut

__PACKAGE__->table("gazetteer");

=head1 ACCESSORS

=head2 gaz_id

  data_type: 'varchar'
  is_nullable: 0
  size: 12

=head2 description

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=cut

__PACKAGE__->add_columns(
  "gaz_id",
  { data_type => "varchar", is_nullable => 0, size => 12 },
  "description",
  { data_type => "varchar", is_nullable => 1, size => 45 },
);

=head1 PRIMARY KEY

=over 4

=item * L</gaz_id>

=back

=cut

__PACKAGE__->set_primary_key("gaz_id");

=head1 RELATIONS

=head2 samples

Type: has_many

Related object: L<Bio::HICF::Schema::Result::Sample>

=cut

__PACKAGE__->has_many(
  "samples",
  "Bio::HICF::Schema::Result::Sample",
  { "foreign.location" => "self.gaz_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-01-22 10:51:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AVv8UUK7VE0XvqLxJLQBKg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
