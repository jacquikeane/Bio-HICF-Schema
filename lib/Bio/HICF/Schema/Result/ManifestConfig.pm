use utf8;
package Bio::HICF::Schema::Result::ManifestConfig;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Bio::HICF::Schema::Result::ManifestConfig - Stores the configuration for a given manifest.

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

=head1 TABLE: C<manifest_config>

=cut

__PACKAGE__->table("manifest_config");

=head1 ACCESSORS

=head2 config_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 config

  data_type: 'mediumtext'
  is_nullable: 0

The configuration string, suitable for generating a Bio::Metadata::Config object

=head2 name

  data_type: 'tinytext'
  is_nullable: 1

The name of a configuration in a multi-part configuration. Not required if the configuration string has only a single <checklist> block.

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
  "config_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "config",
  { data_type => "mediumtext", is_nullable => 0 },
  "name",
  { data_type => "tinytext", is_nullable => 1 },
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

=item * L</config_id>

=back

=cut

__PACKAGE__->set_primary_key("config_id");

=head1 RELATIONS

=head2 manifests

Type: has_many

Related object: L<Bio::HICF::Schema::Result::Manifest>

=cut

__PACKAGE__->has_many(
  "manifests",
  "Bio::HICF::Schema::Result::Manifest",
  { "foreign.config_id" => "self.config_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-02-04 13:47:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:sQSdDb09rQAp3LItXzfUjA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
