use utf8;
package Bio::HICF::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Bio::HICF::Schema::Result::User

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

=head1 TABLE: C<user>

=cut

__PACKAGE__->table("user");

=head1 ACCESSORS

=head2 username

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 passphrase

  data_type: 'varchar'
  is_nullable: 0
  passphrase: 'rfc2307'
  passphrase_args: {algorithm => "SHA-1",salt_random => 20}
  passphrase_check_method: 'check_password'
  passphrase_class: 'SaltedDigest'
  size: 128

=head2 displayname

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 email

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 roles

  data_type: 'varchar'
  default_value: 'user'
  is_nullable: 1
  size: 128

=head2 api_key

  data_type: 'char'
  is_nullable: 1
  size: 32

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
  "username",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "passphrase",
  {
    data_type => "varchar",
    is_nullable => 0,
    passphrase => "rfc2307",
    passphrase_args => { algorithm => "SHA-1", salt_random => 20 },
    passphrase_check_method => "check_password",
    passphrase_class => "SaltedDigest",
    size => 128,
  },
  "displayname",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "email",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "roles",
  {
    data_type => "varchar",
    default_value => "user",
    is_nullable => 1,
    size => 128,
  },
  "api_key",
  { data_type => "char", is_nullable => 1, size => 32 },
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

=item * L</username>

=back

=cut

__PACKAGE__->set_primary_key("username");

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Bio::HICF::Schema::Role::User>

=back

=cut


with 'Bio::HICF::Schema::Role::User';


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-04-14 15:04:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2IE91W6yy0F+049zTbt+3A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
