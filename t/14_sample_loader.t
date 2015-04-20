
use strict;
use warnings;

use Test::More;
use Test::CacheFile;
use Test::Exception;
use Test::Warn;
use Test::Script::Run;
use Archive::Tar;
use File::Path qw(make_path remove_tree);
use File::Copy qw(copy);
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

diag 'caching ontology/taxonomy files';
Test::CacheFile::cache( 'http://purl.obolibrary.org/obo/subsets/envo-basic.obo', 'envo-basic.obo' );
Test::CacheFile::cache( 'http://purl.obolibrary.org/obo/gaz.obo', 'gaz.obo' );
Test::CacheFile::cache( 'http://www.brenda-enzymes.info/ontology/tissue/tree/update/update_files/BrendaTissueOBO', 'bto.obo' );
Test::CacheFile::cache( 'ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz', 'taxdump.tar.gz' );

# extract the names.dmp from the taxdump archive
if ( ! -f '.cached_test_files/names.dmp' ) {
  my $tar = Archive::Tar->new('.cached_test_files/taxdump.tar.gz');
  $tar->extract_file( 'names.dmp', '.cached_test_files/names.dmp' );
}

# make the directories for the tests
make_path( 't/data/storage/archive',
           't/data/storage/dropbox',
           't/data/storage/failed' );

#-------------------------------------------------------------------------------

BEGIN { use_ok( 'Bio::HICF::SampleLoader' ) }

$ENV{HICF_STORAGE} = getcwd;

# test errors with instantiation first

throws_ok { Bio::HICF::SampleLoader->new }
  qr/must specify a script configuration/,
  'got expected exception when HICF_SCRIPT_CONFIG not set';

$ENV{HICF_SCRIPT_CONFIG} = 'non-existent file';
throws_ok { Bio::HICF::SampleLoader->new }
  qr/can't find config file/,
  'got expected exception when HICF_SCRIPT_CONFIG points to non-existent file';

# point to a file that will make Config::General complain
$ENV{HICF_SCRIPT_CONFIG} = 't/14_sample_loader.t';
throws_ok { Bio::HICF::SampleLoader->new }
  qr/loaded script config is not valid/,
  'got expected exception when HICF_SCRIPT_CONFIG points to an unparseable file';

$ENV{HICF_SCRIPT_CONFIG} = 't/data/14_broken_script.conf';
throws_ok { Bio::HICF::SampleLoader->new }
  qr/path for required directory 'dropbox'/,
  'got expected exception when HICF_SCRIPT_CONFIG has bad directory paths';

$ENV{HICF_SCRIPT_CONFIG} = 't/data/14_script.conf';
my $loader = new_ok( 'Bio::HICF::SampleLoader' );

lives_ok { $loader->find_files } 'no error when finding files';

# currently no files to find...
is $loader->count_files, 0, 'no files found';

# try finding a file with an invalid name
copy 't/data/14_ERS123456_68d4f8aa49ba39839f2d47a569760742.fa',
     't/data/storage/dropbox/bad_name';

warning_like { $loader->find_files }
  qr/not have the correct format/,
  'got filename format warning';
is $loader->count_files, 0, 'no files found';
ok ! -e 't/data/storage/dropbox/bad_name', 'bad file no longer in "dropbox" dir';
ok -e 't/data/storage/failed/bad_name', 'bad file moved to "failed" dir';
unlink 't/data/storage/failed/bad_name';

# try an empty file
open( EMPTY, '>t/data/storage/dropbox/ERS123456_68d4f8aa49ba39839f2d47a569760742.fa' );
close EMPTY;


warning_like { $loader->find_files } qr/is empty/, 'got empty file warning';
is $loader->count_files, 0, 'no files found';
ok ! -e 't/data/storage/dropbox/ERS123456_68d4f8aa49ba39839f2d47a569760742.fa',
  'bad file no longer in "dropbox" dir';
ok -e 't/data/storage/failed/ERS123456_68d4f8aa49ba39839f2d47a569760742.fa',
  'bad file moved to "failed" dir';
unlink 't/data/storage/failed/ERS123456_68d4f8aa49ba39839f2d47a569760742.fa';

# try a directory
mkdir 't/data/storage/dropbox/ERS123456_68d4f8aa49ba39839f2d47a569760742.fa';

warning_like { $loader->find_files } qr/is not a file/, 'got "not a file" warning';
is $loader->count_files, 0, 'no files found';
ok ! -e 't/data/storage/dropbox/ERS123456_68d4f8aa49ba39839f2d47a569760742.fa',
  'bad file no longer in "dropbox" dir';
ok -e 't/data/storage/failed/ERS123456_68d4f8aa49ba39839f2d47a569760742.fa',
  'bad file moved to "failed" dir';
rmdir 't/data/storage/failed/ERS123456_68d4f8aa49ba39839f2d47a569760742.fa';

# try finding a file with a bad MD5
copy 't/data/14_ERS123456_68d4f8aa49ba39839f2d47a569760742.fa',
     't/data/storage/dropbox/ERS123456_11111111111111111111111111111111.fa';

warning_like { $loader->find_files }
  qr/calculated checksum/,
  'got filename checksum warning';
is $loader->count_files, 0, 'no files found';
ok ! -e 't/data/storage/dropbox/ERS123456_11111111111111111111111111111111.fa',
  'bad file no longer in "dropbox" dir';
ok -e  't/data/storage/failed/ERS123456_11111111111111111111111111111111.fa',
  'bad file moved to "failed" dir';
unlink 't/data/storage/failed/ERS123456_11111111111111111111111111111111.fa';

# finally, try finding a valid file
copy 't/data/14_ERS123456_68d4f8aa49ba39839f2d47a569760742.fa',
     't/data/storage/dropbox/ERS111111_68d4f8aa49ba39839f2d47a569760742.fa';
warning_like { $loader->find_files } undef, 'no warning when finding valid file';
is $loader->count_files, 1, 'one file found';
ok -e 't/data/storage/dropbox/ERS111111_68d4f8aa49ba39839f2d47a569760742.fa',
  'valid file still in "dropbox" dir';
ok ! -e 't/data/storage/failed/ERS111111_68d4f8aa49ba39839f2d47a569760742.fa',
  'valid file not moved to "failed" dir';

# having found that file, try loading it
lives_ok { $loader->load_files } 'loaded found file';

ok ! -e 't/data/storage/dropbox/ERS111111_68d4f8aa49ba39839f2d47a569760742.fa',
  'valid file no longer in "dropbox" dir';

my @archived_files = File::Find::Rule->file()
                            ->name( '*.fa' )
                            ->in( 't/data/storage/archive' );
is scalar @archived_files, 1, 'valid file moved to "archve" dir';

# tidy up the file we created
remove_tree( 't/data/storage' );

done_testing;

