
use strict;
use warnings;

use Test::More;
use Test::CacheFile;
use Test::Exception;
use Test::Script::Run;

# NOTE: this test has to write the test database to disk, rather than using an
# in-memory DB. Because of that, if the test database already exists, strange
# things can happen, e.g. fixture loading can fail because the new data can hit
# unique key constraints if it's loaded over the top of existing data. If you
# get test failures with this file, make sure there's no file called "test.db"
# in the cwd.

use Test::DBIx::Class {
  connect_info => [ 'dbi:SQLite:dbname=test.db', '', '' ],
}, qw( :resultsets );

# load the pre-requisite data
fixtures_ok 'main', 'installed fixtures';

my $script = 'bin/load_tax_tree';

run_ok( $script, [ qw( -h ) ], 'script runs ok with help flag' );
run_not_ok( $script, [ ], 'script exits with error status when run with no arguments' );

my ( $rv, $stdout, $stderr ) = run_script( $script, [] );
like( $stderr, qr/ERROR: you must specify a configuration file/, 'got expected error message with no flags' );

is( Taxonomy->count, 2, 'found two rows in taxonomy table before loading' );

( $rv, $stdout, $stderr ) = run_script( $script, [ qw(-c t/data/06_tax_tree.conf) ] );
unlike( $stderr, qr/ERROR/, 'no loading error with valid configs and manifest' );

is( Taxonomy->count, 12, 'got expected number of rows in taxonomy table after load' );

is( ExternalResource->count, 1, 'found an external resource record' );
my $r = ExternalResource->search( { name => 'taxdump' }, {} )->first;
is( $r->checksum, 'd2252a42f03b9aa5f566fc8192818b8a', 'got expected checksum for resource' );

$DB::single = 1;

# clean up, unless asked not to
unlink 'test.db' unless $ENV{KEEP_DB};

done_testing;

