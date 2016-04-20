
use strict;
use warnings;

use Test::More tests => 57;
use Test::Exception;

#-------------------------------------------------------------------------------
# DB setup

# the default behaviour of Test::DBIx::Class should be to remove the database
# file unless explicitly told to keep it. By default it should also re-deploy
# the schema every time, even if the database exists.
#
# Neither of those default behaviours seem to be working properly, so there is
# likely to be a "test.db" file left lying around after running these tests,
# and re-running them may cause errors because the database is not being wiped
# clean before loading duplicate rows.
#
# Delete "test.db" before re-running tests, just to be sure that the test DB
# is re-created correctly on each run.

use Test::DBIx::Class {
  connect_info => [ 'dbi:SQLite:dbname=test.db', '', '' ],
};

#-------------------------------------------------------------------------------

is( User->count, 0, 'no users before load' );

my $user_details = {
  username    => 'user1',
  passphrase  => 'user1_passphrase',
  displayname => 'User One',
  email       => 'user@example.com',
};

lives_ok { Schema->add_new_user($user_details) }
  'no error when adding new user';

is( User->count, 1, 'one user after load' );

# "find_user"
is Schema->find_user('nonexistentuser'), undef,
  '"find_user" returns undef for non-existent user';

throws_ok { Schema->find_user }
  qr/must supply a username/,
  'exception from "find_user" with no username';

my $user;
ok $user = Schema->find_user('user1'), '"find_user" returns a user';

isa_ok $user, 'Bio::HICF::User::Result::User', 'got User row';

ok   Schema->is_active('user1'), 'user is active';
ok ! Schema->is_deleted('user1'), 'user is not deleted';

ok   $user->is_active, 'user is active';
ok ! $user->is_deleted, 'user is not deleted';

my $user_row = User->find('user1');
is $user_row->deleted_at, undef, '"deleted_at" has NO value for live user';

# "delete_user"
throws_ok { Schema->delete_user }
  qr/must supply a username/,
  'exception from "delete_user" with no username';

throws_ok { Schema->delete_user('nonexistentuser') }
  qr/does not exist/,
  'exception from "delete_user" with non-existent username';

# delete a real user and make sure we don't get it back with "find_user"
lives_ok { Schema->delete_user('user1') }
  'no exception from "delete_user" with valid username';

is Schema->find_user('user1'), undef, 'no deleted user via "find_user"';

$user_row = User->find('user1');
ok $user_row->deleted_at, '"deleted_at" has a value for deleted user';

ok ! Schema->is_active('user1'), 'user is not active';
ok   Schema->is_deleted('user1'), 'user is deleted';

# because the state of the object in $user is not updated when we run
# Schema->delete_user, checking it with $user->is_active will give us
# a result from *before* we ran "delete_user". Instead we need to
# check with the row that we created after we ran "delete_user".
ok ! $user_row->is_active, 'user is not active';
ok   $user_row->is_deleted, 'user is deleted';

# re-enable the deleted user
$user_row->update( { deleted_at => undef } );

# check other stored values for the user
is( $user->email, $user_details->{email}, 'got expected email address from DB' );

ok( $user->check_password('user1_passphrase'), 'passphrase checks out' );

isa_ok( $user->passphrase, 'Authen::Passphrase' );

ok( $user->passphrase('new_passphrase'), 'successfully reset passphrase for user' );
ok( $user->check_password('new_passphrase'), 'new passphrase checks out' );

# can't create two users with the same username
throws_ok { Schema->add_new_user($user_details) }
  qr/user already exists/,
  'got expected error when adding same user again';

# add a second user
$user_details->{username} = 'user2';

my $returned_passphrase;
lives_ok { $returned_passphrase = Schema->add_new_user($user_details) }
  'no error when adding second new user';

is( $returned_passphrase, undef, 'returned passphrase is undefined' );

is( User->count, 2, 'two users after loading second user' );

User->find('user2')->delete;

$user_details->{passphrase} = undef;

$returned_passphrase = Schema->add_new_user($user_details);
like( $returned_passphrase, qr/^[A-Za-z0-9]{8}$/, "returned passphrase ($returned_passphrase) looks sensible" );

User->find('user2')->delete;

$user_details->{passphrase} = '';

$returned_passphrase = Schema->add_new_user($user_details);
like( $returned_passphrase, qr/^[A-Za-z0-9]{8}$/, "returned passphrase ($returned_passphrase) looks sensible when passing in '' for passphrase" );

$user_details->{displayname} = 'A User';
lives_ok { Schema->update_user($user_details) }
  'updated user details';

$user = User->find('user2');
is( $user->displayname, 'A User', 'display name updated successfully' );

throws_ok { Schema->update_user({username => 'user1'}) }
  qr/must supply fields/,
  "can't update without fields";

throws_ok { Schema->update_user({username => 'nosuchuser', displayname => 'User'}) }
  qr/does not exist/,
  "can't update a non-existent user";

lives_ok { Schema->set_passphrase( 'user1', 'new_passphrase' ) }
  'set passphrase successfully';

ok( User->find('user1')->check_password('new_passphrase'), 'new passphrase is correct' );

throws_ok { Schema->set_passphrase( 'nosuchuser', 'new_passphrase' ) }
  qr/does not exist/,
  'failed to set passphrase for non-existent user';

throws_ok { Schema->reset_passphrase('nosuchuser') }
  qr/does not exist/,
  "can't reset passphrase for non-existent user";

my $new_passphrase;
lives_ok { $new_passphrase = Schema->reset_passphrase('user1') }
  'reset passphrase for user';

ok( $new_passphrase, 'got a new passphrase' );

$user = User->find('user1');
ok( $user->check_password($new_passphrase), 'new passphrase checks out' );

my $passphrase;
ok( $passphrase = Schema->generate_passphrase, 'password generation works' );
is( length $passphrase, 8, 'default passphrase contains 8 characters' );

ok( $passphrase = Schema->generate_passphrase(32), 'password generation works with length specified' );
like( $passphrase, qr/^[A-Za-z0-9]{32}$/, 'passphrase has sensible content' );

is( $user->api_key, undef, 'no API key for user before setting it' );
my $key;
lives_ok { $key = $user->reset_api_key } 'no error when resetting API key';
like( $key, qr/^[A-za-z0-9]{32}$/, "key looks sensible ('$key')" );

my $new_key;
lives_ok { $new_key = $user->reset_api_key } 'no error when resetting a second time';
like( $new_key, qr/^[A-za-z0-9]{32}$/, "new key looks sensible ('$new_key')" );
isnt( $key, $new_key, 'key has changed' );

throws_ok { Schema->reset_api_key() }
  qr/must supply a username/,
  'error when trying to reset API key while not supplying username';
throws_ok { Schema->reset_api_key('nonexistentuser') }
  qr/does not exist/,
  'error when trying to reset API key for non-existent user';
lives_ok { $key = Schema->reset_api_key('user1') } 'can reset password via schema';
isnt( $key, $new_key, 'key has changed' );

# done_testing;

