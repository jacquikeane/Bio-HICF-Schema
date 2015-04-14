use utf8;
package Bio::HICF::Schema::Result::Checklist;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Bio::HICF::Schema::Result::Checklist - Stores the configuration for a given manifest.

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

=head1 TABLE: C<checklist>

=cut

__PACKAGE__->table("checklist");

=head1 ACCESSORS

=head2 checklist_id

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

=cut

__PACKAGE__->add_columns(
  "checklist_id",
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
);

=head1 PRIMARY KEY

=over 4

=item * L</checklist_id>

=back

=cut

__PACKAGE__->set_primary_key("checklist_id");

=head1 RELATIONS

=head2 manifests

Type: has_many

Related object: L<Bio::HICF::Schema::Result::Manifest>

=cut

__PACKAGE__->has_many(
  "manifests",
  "Bio::HICF::Schema::Result::Manifest",
  { "foreign.checklist_id" => "self.checklist_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-04-14 15:55:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Kh7k47tKOG8I8vsItkryiw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
