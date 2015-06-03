
use strict;
use warnings;

use Test::More tests => 20;
use Test::Exception;
use Test::Script::Run;
use File::Path qw(make_path remove_tree);
use File::Copy qw(copy move);
use File::Find::Rule;
use Cwd;

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

# set up the location of the test directories. It's assumed that you're running
# this test from the top-level directory of the module tree
# TODO use File::Temp to make this safer and cleaner
$ENV{HICF_STORAGE} = getcwd;

my $archive = $ENV{HICF_STORAGE} . '/t/data/storage/archive';
my $dropbox = $ENV{HICF_STORAGE} . '/t/data/storage/dropbox';
my $failed  = $ENV{HICF_STORAGE} . '/t/data/storage/failed';

make_path( $archive, $dropbox, $failed );

# a File::Find::Rule to search for files (as opposed to directories)
my $finder = File::Find::Rule->file;

#-------------------------------------------------------------------------------

my $script = 'bin/load_samples_cron';

delete $ENV{HICF_SCRIPT_CONFIG};

# should be no output if there are no files to find
my ( $rv, $stdout, $stderr ) = run_script( $script );
like $stderr,
  qr/ERROR: must specify a script configuration file/,
  'got expected error message with no config specified';

$ENV{HICF_SCRIPT_CONFIG} = 't/data/15_cron.conf';

run_ok( $script, 'script runs ok with no files to find' );

is $finder->in($archive), 0, 'no files in archive';
is $finder->in($dropbox), 0, 'no files in dropbox';
is $finder->in($failed),  0, 'found file in failed';

# test a problem that generates a warning
copy 't/data/15_ERS123456_68d4f8aa49ba39839f2d47a569760742.fa',
     't/data/storage/dropbox/bad_file_name';

( $rv, $stdout, $stderr ) = run_script( $script );
like $stderr,
  qr/WARNING: filename 'bad_file_name' does not have the correct format/,
  'got expected warning with bad filename in dropbox';

is $finder->in($archive), 0, 'no files in archive';
is $finder->in($dropbox), 0, 'no files in dropbox';
is $finder->in($failed),  1, 'found file in failed';

# and one that generates an error
copy 't/data/15_ERS123456_68d4f8aa49ba39839f2d47a569760742.fa',
     't/data/storage/dropbox/ERS123456_68d4f8aa49ba39839f2d47a569760742.fa';

( $rv, $stdout, $stderr ) = run_script( $script );
like $stderr,
  qr/ERROR: no such sample/,
  'got expected error with file having no matching accesson in database';

is $finder->in($archive), 0, 'no files in archive';
is $finder->in($dropbox), 1, 'found latest file in dropbox';
is $finder->in($failed),  1, 'found previous file in failed';

# move the bad file out of the way and actually load a good one
unlink 't/data/storage/dropbox/ERS123456_68d4f8aa49ba39839f2d47a569760742.fa';
copy 't/data/15_ERS123456_68d4f8aa49ba39839f2d47a569760742.fa',
     't/data/storage/dropbox/ERS111111_68d4f8aa49ba39839f2d47a569760742.fa';

( $rv, $stdout, $stderr ) = run_script( $script );
is $stdout, '', 'no output with valid file';
is $stderr, '', 'no error with valid file';

is $finder->in($archive), 1, 'found latest file in archive';
is $finder->in($dropbox), 0, 'no files in dropbox';
is $finder->in($failed),  1, 'found previous file in failed';

$DB::single = 1;

done_testing;

# tidy up
remove_tree( $ENV{HICF_STORAGE} . '/t/data/storage' );

