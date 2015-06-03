
use strict;
use warnings;

use Test::More tests => 14;
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

my $preload = sub {
  my ( $storage, $dbh, @other_args ) = @_;
  $dbh->do( 'PRAGMA foreign_keys = ON' );
};

lives_ok { Schema->storage->dbh_do($preload) } 'successfully turned on "foreign_keys" pragma';

#-------------------------------------------------------------------------------

my $script = 'bin/load_manifest';

run_ok( $script, [ qw( -h ) ], 'script runs ok with help flag' );
run_not_ok( $script, [ ], 'script exits with error status when run with no arguments' );

my ( $rv, $stdout, $stderr ) = run_script( $script, [] );
like( $stderr, qr/ERROR: you must specify a checklist configuration file/, 'got expected error message with no flags' );

SKIP: {
  skip 'error message testing', 6 if $ENV{SKIP_ERROR_TESTS};

  ( $rv, $stdout, $stderr ) = run_script( $script, [ qw(-c t/data/13_checklist.conf) ] );
  like( $stderr, qr/ERROR: you must specify a script configuration file/, 'got expected error message with just -c flag' );

  ( $rv, $stdout, $stderr ) = run_script( $script, [ qw(-c t/data/13_checklist.conf        -d t/data/test_config.conf) ] );
  like( $stderr, qr/ERROR: you must specify an input file/, 'got expected error message with -c and -s flags' );

  ( $rv, $stdout, $stderr ) = run_script( $script, [ qw(-c t/data/13_checklist.conf        -d t/data/13_broken_test_config.conf t/data/13_manifest.csv) ] );
  like( $stderr, qr/ERROR: there was a problem reading the script configuration.*? no EndBlock/, 'got expected error message with broken script config' );

  ( $rv, $stdout, $stderr ) = run_script( $script, [ qw(-c t/data/13_checklist.conf        -d t/data/13_bad_db_script.conf      t/data/13_manifest.csv) ] );
  like( $stderr, qr/ERROR: could not connect/, 'got expected error message with bad script config' );

  ( $rv, $stdout, $stderr ) = run_script( $script, [ qw(-c t/data/13_checklist.conf        -d t/data/13_script.conf             t/data/13_broken_manifest.csv) ] );
  like( $stderr, qr/ERROR: there was a problem loading.*? data in the manifest are not valid/, 'got expected error message with invalid manifest' );

  ( $rv, $stdout, $stderr ) = run_script( $script, [ qw(-c t/data/13_broken_checklist.conf -d t/data/13_script.conf             t/data/13_manifest.csv) ] );
  like( $stderr, qr/ERROR: could not load configuration/, 'got expected error message with broken checklist config' );
}

is( Sample->count, 1, 'found one row in sample table before loading' );

( $rv, $stdout, $stderr ) = run_script( $script, [ qw(-c t/data/13_checklist.conf -d t/data/13_script.conf t/data/13_manifest.csv) ] );
unlike( $stderr, qr/ERROR/, 'no loading error with valid configs and manifest' );

is( Sample->count, 3, 'got expected number of rows in sample table' );

$DB::single = 1;

done_testing;

# tidy up an empty DB created by one of the tests
unlink 'nonexistent.db';

