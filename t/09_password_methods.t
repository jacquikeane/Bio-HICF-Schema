
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

ok( $user->check_passphrase('user1_passphrase'), 'password checks out' );

isa_ok( $user->passphrase, 'Authen::Passphrase' );

ok( $user->passphrase('new_passphrase'), 'successfully reset password for user' );
ok( $user->check_passphrase('new_passphrase'), 'new password checks out' );

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

done_testing;

__END__

lives_ok { Schema->load_antimicrobial_resistance(%amr) }
  'no error when adding a new valid amr';

$amr{sample_id} = 99;
throws_ok { Schema->load_antimicrobial_resistance(%amr) }
  qr/both the antimicrobial and the sample/,
  'error when adding an amr with a missing sample ID';

