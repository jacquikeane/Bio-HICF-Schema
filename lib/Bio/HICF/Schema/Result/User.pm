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
);

=head1 PRIMARY KEY

=over 4

=item * L</username>

=back

=cut

__PACKAGE__->set_primary_key("username");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-03-19 15:11:13
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XFKtHemFVcwdXtHth13kww

=head2 set_passphrase($passphrase)

Sets the passphrase for this user.

=cut

sub set_passphrase {
  my ( $self, $passphrase ) = @_;

  $self->update( { passphrase => $passphrase } );
}

#-------------------------------------------------------------------------------

=head2 reset_passphrase

Generates a new passphrase for the current user. The passphrase is set on the
row and returned to the caller.

=cut

sub reset_passphrase {
  my $self = shift;

  my $generated_passphrase = $self->result_source->schema->generate_passphrase;

  $self->update( { passphrase => $generated_passphrase } );

  return $generated_passphrase;
}

#-------------------------------------------------------------------------------

=head2 reset_api_key

Resets the API key for this user and returns it.

=cut

sub reset_api_key {
  my $self = shift;

  my $api_key = $self->result_source->schema->generate_passphrase(32);

  $self->update( { api_key => $api_key } );

  return $api_key;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;
1;
