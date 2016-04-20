use utf8;
package Bio::HICF::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-05-27 12:12:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2jMKzUnbWM49BFVwNZBCOg

# ABSTRACT: DBIC schema for the HICF user data repository

=head1 SYNOPSIS

 # connect
 my $schema = Bio::HICF::Schema->connect( $dsn, $username, $password );

 # generate a new user
 my $generated_passphrase = $schema->add_new_user( $username, $display_name, $email );

 # update details for an existing user
 $schema->update_user( {
  username    => $user,
  displayname => 'New Name',
 } );

 # set the passphrase for an existing user
 $schema->set_passphrase( $username, $passphrase );

 # reset the passphrase or API key for a user
 my $new_passphrase = $schema->reset_passphrase( $username );
 my $new_api_key    = $schema->reset_api_key( $username );

=cut

use MooseX::Params::Validate;
use Carp qw( croak );
use Try::Tiny;
use Email::Valid;
use File::Basename;
use List::MoreUtils qw( mesh );
use DateTime;

use Bio::Metadata::Types qw( UUID OntologyTerm );
use Bio::Metadata::Checklist;
use Bio::Metadata::Validator;
use Bio::Metadata::TaxTree;

#-------------------------------------------------------------------------------

=head1 DESCRIPTION

This is the L<DBIx::Class::Schema> API for the HICF user data database. It
contains methods for performing operations on user information such as
passwords.

=head1 METHODS

=cut

#-------------------------------------------------------------------------------

=head2 add_new_user($user_details)

Adds a new user to the database. Requires one argument, a reference to a hash
containing the following keys:

=over 4

=item username

=item displayname

=item email

=item passphrase [optional]

=back

If the key C<passphrase> is present in the hash, its value will be used to set
the passphrase for the user and the return value will be C<undef>. If there is
no supplied passphrase, a random passphrase will be generated and returned.

=cut

sub add_new_user {
  my ( $self, $fields ) = @_;

  croak 'ERROR: one of the required fields is missing'
    unless ( defined $fields->{username} and
             defined $fields->{displayname} and
             defined $fields->{email} );

  # make sure the email address is at least well-formed
  croak "ERROR: not a valid email address ($fields->{email})"
    unless Email::Valid->address($fields->{email});

  my $column_values = {
    username    => $fields->{username},
    displayname => $fields->{displayname},
    email       => $fields->{email},
  };

  my $generated_passphrase;
  if ( defined $fields->{passphrase} and
       $fields->{passphrase} ne '' ) {
    $column_values->{passphrase} = $fields->{passphrase}
  }
  else {
    # generate a random passphrase and store that
    $generated_passphrase = $self->generate_passphrase;
    $column_values->{passphrase} = $generated_passphrase;
  }

  # TODO maybe implement roles

  my $user = $self->resultset('User')
                  ->find_or_new( $column_values );

  croak 'ERROR: user already exists; use "update_user" to update'
    if $user->in_storage;

  $user->insert;

  return $generated_passphrase;
}

#-------------------------------------------------------------------------------

=head2 find_user($username)

Returns the row for the specified user. Requires one argument, giving the
username of the user. Croaks if the username is not supplied. Returns undef if
the username does not return a row.

=cut

sub find_user {
  my ( $self, $username ) = @_;

  croak 'ERROR: must supply a username'
    unless defined $username;

  my $user_rs = $self->resultset('User')->search(
    {
      username   => $username,
      deleted_at => undef,
    }
  );

  return unless ( defined $user_rs and $user_rs->count == 1 );

  return $user_rs->first;
}

#-------------------------------------------------------------------------------

=head2 delete_user($username)

Delete the specified user. Requires one argument, the username of the user to
be deleted. Croaks is a username is not supplied, or if a user with that
username is not found.

Note that the user account is not really deleted. Instead, its "deleted_at"
field is set to the current time.

=cut

sub delete_user {
  my ( $self, $username ) = @_;

  croak 'ERROR: must supply a username'
    unless defined $username;

  my $user = $self->find_user($username);

  croak "ERROR: user '$username' does not exist"
    unless defined $user;

  $user->update( { deleted_at => DateTime->now } );
}

#-------------------------------------------------------------------------------

=head2 update_user($user_details)

Update the details for the specified user. Requires a single argument, a
reference to a hash containg the user details. The hash must contain the
key C<username>, plus one or more other fields to update. An exception is
thrown if the username is not supplied, if there are no fields to update,
or if the user does not exist.

These are the allowed fields:

=over 4

=item username

=item displayname

=item email

=item passphrase

=back

=cut

sub update_user {
  my ( $self, $fields ) = @_;

  croak 'ERROR: must supply a username'
    unless defined $fields->{username};

  # we need something to update...
  croak 'ERROR: must supply fields to update'
    unless scalar( keys %$fields ) > 1;

  my $column_values = {
    username => $fields->{username},
  };

  if ( defined $fields->{email} ) {
    # make sure the email address is at least well-formed
    croak "ERROR: not a valid email address ($fields->{email})"
      unless Email::Valid->address($fields->{email});
    $column_values->{email} = $fields->{email};
  }

  $column_values->{displayname} = $fields->{displayname} if defined $fields->{displayname};
  $column_values->{passphrase}  = $fields->{passphrase}  if defined $fields->{passphrase};

  # TODO maybe implement roles

  my $user = $self->find_user( $column_values->{username} );

  croak "ERROR: user '$fields->{username}' does not exist; use 'add_user' to add"
    unless defined $user;

  $user->update( $column_values );
}

#-------------------------------------------------------------------------------

=head2 set_passphrase($username,$passphrase)

Set the passphrase for the specified user.

=cut

sub set_passphrase {
  my ( $self, $username, $passphrase ) = @_;

  croak 'ERROR: must supply a username and a passphrase'
    unless ( defined $username and defined $passphrase );

  my $user = $self->find_user($username);

  croak "ERROR: user '$username' does not exist; use 'add_user' to add"
    unless defined $user;

  $user->set_passphrase($passphrase);
}

#-------------------------------------------------------------------------------

=head2 reset_passphrase($username)

Resets the password for the specified user. The reset password is automatically
generated and is returned to the caller.

=cut

sub reset_passphrase {
  my ( $self, $username ) = @_;

  croak 'ERROR: must supply a username' unless defined $username;

  my $user = $self->find_user($username);

  croak "ERROR: user '$username' does not exist; use 'add_user' to add"
    unless defined $user;

  return $user->reset_passphrase;
}

#-------------------------------------------------------------------------------

=head2 reset_api_key($username)

Reset the API key for the specified user. The API key cannot be supplied; it
will be generated automatically and returned to the caller.

=cut

sub reset_api_key {
  my ( $self, $username ) = @_;

  croak 'ERROR: must supply a username' unless defined $username;

  my $user = $self->find_user($username);

  croak "ERROR: user '$username' does not exist; use 'add_user' to add"
    unless defined $user;

  $user->reset_api_key;

  return $user->api_key;
}

#-------------------------------------------------------------------------------

=head2 generate_passphrase($length?)

Generates a random passphrase string. If C<$length> is supplied, the passphrase
will contain C<$length> characters from the set C<[A-NP-Za-z1-9]> i.e. omitting
zero and the capital letter "O", for clarity. If C<$length> is not specified, the
passphrase will contain 8 characters.

=cut

# TODO this should be moved into a base class that everything else inherits from
# TODO or, more properly, a Moose Role

sub generate_passphrase {
  my ( $self, $length ) = @_;

  $length ||= 8;

  my $generated_passphrase = '';
  $generated_passphrase .= ['1'..'9','A'..'N','P'..'Z','a'..'z']->[rand 52] for 1..$length;

  return $generated_passphrase;
}

#-------------------------------------------------------------------------------

=head1 SEE ALSO

L<Bio::HICF::Schema>
L<Bio::Metadata::Validator>

=head1 CONTACT

path-help@sanger.ac.uk

=cut

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;
