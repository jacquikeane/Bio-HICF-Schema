use utf8;
package Bio::HICF::Schema::Result::ExternalResource;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Bio::HICF::Schema::Result::ExternalResource

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

=head1 TABLE: C<external_resources>

=cut

__PACKAGE__->table("external_resources");

=head1 ACCESSORS

=head2 resource_id

  data_type: 'integer'
  is_nullable: 0

=head2 source

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 retrieved_at

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 checksum

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=head2 version

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=cut

__PACKAGE__->add_columns(
  "resource_id",
  { data_type => "integer", is_nullable => 0 },
  "source",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "retrieved_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "checksum",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "version",
  { data_type => "varchar", is_nullable => 1, size => 45 },
);

=head1 PRIMARY KEY

=over 4

=item * L</resource_id>

=back

=cut

__PACKAGE__->set_primary_key("resource_id");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-01-14 15:53:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XXsGwYF2OYO0wJyAWZFvvw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
