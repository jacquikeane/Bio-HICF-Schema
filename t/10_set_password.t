
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

my $script = 'bin/set_midas_password';

run_ok( $script, [ qw( -h ) ], 'script runs ok with help flag' );
run_not_ok( $script, [ ], 'script exits with error status when run with no arguments' );

my ( $rv, $stdout, $stderr ) = run_script( $script, [] );
like $stderr, qr/ERROR: you must specify a script configuration file/,
  'got expected error message with no flags';

( $rv, $stdout, $stderr ) = run_script( $script, [ qw(-d t/data/09_broken.conf) ] );
like $stderr, qr/ERROR: you must specify a username/,
  'got expected error message with no username';

( $rv, $stdout, $stderr ) = run_script( $script, [ qw(-d t/data/09_broken.conf -u user) ] );
like $stderr, qr/ERROR: there was a problem/,
  'got expected error message with broken config file';

done_testing;

