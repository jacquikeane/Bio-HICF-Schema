
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

my $script = 'bin/load_ontology';

run_ok( $script, [ qw( -h ) ], 'script runs ok with help flag' );
run_not_ok( $script, [ ], 'script exits with error status when run with no arguments' );

my ( $rv, $stdout, $stderr ) = run_script( $script, [] );
like $stderr, qr/ERROR: you must specify a configuration file/,
  'got expected error message with no flags';

( $rv, $stdout, $stderr ) = run_script( $script, [ qw(-c t/data/08_db.conf) ] );
like $stderr, qr/ERROR: you must specify an ontology name/,
  'got expected error message with no ontology name';

( $rv, $stdout, $stderr ) = run_script( $script, [ qw(-c t/data/08_db.conf -o gazetteer) ] );
like $stderr, qr/ERROR: you must specify an input file/,
  'got expected error message with no input file';

( $rv, $stdout, $stderr ) = run_script( $script, [ qw(-c t/data/08_broken_db_params.conf -o gazetteer t/data/08_gaz.obo) ] );
like $stderr, qr/ERROR: there was a problem reading the config file/,
  'got expected error message with broken config';

is( Gazetteer->count, 1, 'found 1 name before loading' );

( $rv, $stdout, $stderr ) = run_script( $script, [ qw(-c t/data/08_db.conf -o gazetteer t/data/08_broken_gaz.obo) ] );
like $stderr, qr/ERROR: found an invalid ontology term ID/,
  'got expected error message with invalid ontology';

is( Gazetteer->count, 1, 'found 1 name after failed loading' );

( $rv, $stdout, $stderr ) = run_script( $script, [ qw(-c t/data/08_db.conf -o gazetteer t/data/08_gaz.obo) ] );
unlike $stderr, qr/ERROR/,
  'no loading error with valid configs and ontology';

is( Gazetteer->count, 13, 'got expected number of rows in gazetteer table after loading' );

is( ExternalResource->count, 1, 'found an external resource record' );
my $r = ExternalResource->search( { name => 'gazetteer' }, {} )->first;
is( $r->checksum, '87dfedf9bdfa65e70a735238738b778f', 'got expected checksum for resource' );

done_testing;

