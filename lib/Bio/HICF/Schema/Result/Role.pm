use utf8;
package Bio::HICF::Schema::Result::Role;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Bio::HICF::Schema::Result::Role

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

=head1 TABLE: C<role>

=cut

__PACKAGE__->table("role");

=head1 ACCESSORS

=head2 username

  data_type: 'integer'
  is_nullable: 0

=head2 role

  data_type: 'enum'
  extra: {list => ["user","admin"]}
  is_nullable: 0

=head2 user_username

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 64

=cut

__PACKAGE__->add_columns(
  "username",
  { data_type => "integer", is_nullable => 0 },
  "role",
  {
    data_type => "enum",
    extra => { list => ["user", "admin"] },
    is_nullable => 0,
  },
  "user_username",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 64 },
);

=head1 PRIMARY KEY

=over 4

=item * L</role>

=item * L</username>

=item * L</user_username>

=back

=cut

__PACKAGE__->set_primary_key("role", "username", "user_username");

=head1 RELATIONS

=head2 user_username

Type: belongs_to

Related object: L<Bio::HICF::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user_username",
  "Bio::HICF::Schema::Result::User",
  { username => "user_username" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-02-24 16:17:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uduS587aWnI1C9udsOIyQQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
