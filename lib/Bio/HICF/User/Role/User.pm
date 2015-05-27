use utf8;
package Bio::HICF::User::Role::User;

# ABSTRACT: role carrying methods for the AntimicrobialResistance table

use Moose::Role;

requires qw(
  username
  passphrase
  displayname
  email
  roles
  api_key
);

#-------------------------------------------------------------------------------

=head1 METHODS

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

1;

