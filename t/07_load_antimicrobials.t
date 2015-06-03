
use strict;
use warnings;

use Test::More tests => 12;
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

my $script = 'bin/load_antimicrobials';

run_ok( $script, [ qw( -h ) ], 'script runs ok with help flag' );
run_not_ok( $script, [ ], 'script exits with error status when run with no arguments' );

my ( $rv, $stdout, $stderr ) = run_script( $script, [] );
like $stderr, qr/ERROR: you must specify a configuration file/,
  'got expected error message with no flags';

( $rv, $stdout, $stderr ) = run_script( $script, [ qw(-c t/data/07_antimicrobials.conf) ] );
like $stderr, qr/ERROR: you must specify an input file/,
  'got expected error message with just -c flag';

( $rv, $stdout, $stderr ) = run_script( $script, [ qw(-c t/data/07_broken_db_params.conf t/data/07_valid_list.txt) ] );
like $stderr, qr/ERROR: there was a problem reading the config file/,
  'got expected error message with broken config';

is( Antimicrobial->count, 2, 'found 2 names before loading' );

( $rv, $stdout, $stderr ) = run_script( $script, [ qw(-c t/data/07_antimicrobials.conf t/data/07_invalid_list.txt) ] );
like $stderr, qr/Not a valid antimicrobial compound name/,
  'got expected error message with invalid list';

is( Antimicrobial->count, 2, 'found 2 names after failed loading' );

( $rv, $stdout, $stderr ) = run_script( $script, [ qw(-c t/data/07_antimicrobials.conf t/data/07_valid_list.txt) ] );
unlike $stderr, qr/ERROR/,
  'no loading error with valid configs and manifest';

is( Antimicrobial->count, 9, 'got expected number of rows antimicrobial table after loading' );

done_testing;

