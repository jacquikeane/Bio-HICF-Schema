
use strict;
use warnings;

use Test::More;
use File::Temp;
use Test::DBIx::Class qw( :resultsets );
use Test::CacheFile;
use Test::Exception;

# load the pre-requisite data and THEN turn on foreign keys
fixtures_ok 'main', 'installed fixtures';

my $preload = sub {
  my ( $storage, $dbh, @other_args ) = @_;
  $dbh->do( 'PRAGMA foreign_keys = ON' );
};

lives_ok { Schema->storage->dbh_do($preload) } 'successfully turned on "foreign_keys" pragma';

diag 'caching ontology files';
Test::CacheFile::cache( 'http://purl.obolibrary.org/obo/subsets/envo-basic.obo', 'envo-basic.obo' );
Test::CacheFile::cache( 'http://purl.obolibrary.org/obo/gaz.obo', 'gaz.obo' );
Test::CacheFile::cache( 'http://www.brenda-enzymes.info/ontology/tissue/tree/update/update_files/BrendaTissueOBO', 'bto.obo' );

# load new samples via a B::M::Manifest
my $c = Bio::Metadata::Config->new( config_file => 't/data/01_manifest.conf' );
my $r = Bio::Metadata::Reader->new( config => $c );
my $m = $r->read_csv('t/data/01_manifest.csv');

lives_ok { Schema->load_manifest($m) } 'loading valid manifest works';

ok my $sample = Sample->find(2), 'found new sample';
is( AntimicrobialResistance->search({},{})->count, 3, 'found expected number of antimicrobial resistance rows' );

is_fields [ 'raw_data_accession' ], $sample, [ 'rda:2' ], 'new sample row has expected values';

is( $sample->antimicrobial_resistances->count, 2, 'new sample has 2 amr rows' );
is( $sample->antimicrobial_resistances->first->get_column('antimicrobial_name'), 'am1', 'new sample has expected antimicrobial_name' );

# test insert failure behaviour
$m->rows->[0]->[0] = 'rda:3';
$m->rows->[0]->[9] = undef;

$DB::single = 1;

throws_ok { Schema->load_manifest($m) } qr/the data in the manifest are not valid/,
  'got an exception when loading a manifest without a "location" value';

like( $m->row_errors->[0], qr/'location' is a required field/,
  'error in manifest shows "location" as a required field' );

done_testing;

