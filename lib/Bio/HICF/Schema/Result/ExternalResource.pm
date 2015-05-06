use utf8;
package Bio::HICF::Schema::Result::ExternalResource;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Bio::HICF::Schema::Result::ExternalResource

=head1 DESCRIPTION

Details of external resources loaded into or required by the database

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

=head1 TABLE: C<external_resources>

=cut

__PACKAGE__->table("external_resources");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

Unique resource ID

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 45

The name of the resource

=head2 source

  data_type: 'varchar'
  is_nullable: 1
  size: 255

The canonical source of the resource data, such as the URL from which it was downloaded

=head2 retrieved_at

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

The date/time at which the resource file was retrieved from the source

=head2 checksum

  data_type: 'varchar'
  is_nullable: 0
  size: 45

MD5 checksum for the downloaded resource file

=head2 version

  data_type: 'varchar'
  is_nullable: 1
  size: 45

Version number for the resource. If the resource has its own version, that may be stored here, or, if the resource is loaded multiple times, the version may be a simple count of the number of times the resource has been loaded

=head2 created_at

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1
  set_on_create: 1

Date/time at which the resource was created

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "source",
  { data_type => "varchar", is_nullable => 1, size => 255 },
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
  "created_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
    set_on_create => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-04-23 13:38:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0s0Mvuj+53ytwLND8rHDTA


__PACKAGE__->meta->make_immutable;
1;
