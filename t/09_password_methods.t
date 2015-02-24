
use strict;
use warnings;

use Test::More;
use Test::CacheFile;
use Test::Exception;
use Test::Script::Run;

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
}, qw( :resultsets );

# load the pre-requisite data and THEN turn on foreign keys
fixtures_ok 'main', 'installed fixtures';

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

my $user;
ok( $user = User->find('user1'), 'got row using username' );
is( $user->email, $user_details->{email}, 'got expected email address from DB' );

ok( $user->check_passphrase('user1_passphrase'), 'passphrase checks out' );

isa_ok( $user->passphrase, 'Authen::Passphrase' );

ok( $user->passphrase('new_passphrase'), 'successfully reset passphrase for user' );
ok( $user->check_passphrase('new_passphrase'), 'new passphrase checks out' );

throws_ok { Schema->add_new_user($user_details) }
  qr/user already exists/,
  'got expected error when adding same user again';

$user_details->{username} = 'user2';

lives_ok { Schema->add_new_user($user_details) }
  'no error when adding second new user';

is( User->count, 2, 'two users after loading second user' );

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

ok( User->find('user1')->check_passphrase('new_passphrase'), 'new passphrase is correct' );

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
ok( $user->check_passphrase($new_passphrase), 'new passphrase checks out' );

my $passphrase;
ok( $passphrase = Schema->generate_passphrase, 'password generation works' );
is( length $passphrase, 8, 'default passphrase contains 8 characters' );

ok( $passphrase = Schema->generate_passphrase(32), 'password generation works with length specified' );
like( $passphrase, qr/^[A-Za-z0-9]{32}$/, 'passphrase has sensible content' );

done_testing;

