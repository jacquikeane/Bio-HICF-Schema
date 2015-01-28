
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
is( AntimicrobialResistance->search({},{})->count, 5, 'found expected number of antimicrobial resistance rows' );

is_fields [ 'raw_data_accession' ], $sample, [ 'rda:2' ], 'new sample row has expected values';

is( $sample->antimicrobial_resistances->count, 2, 'new sample has 2 amr rows' );
is( $sample->antimicrobial_resistances->first->get_column('antimicrobial_name'), 'am1', 'new sample has expected antimicrobial_name' );

# make sure we can retrieve samples and manifests

# using a single sample ID
my $values;
lives_ok { $values = Schema->get_sample(1) } 'got field values for sample ID 1';

my $expected_values = [ 'data:1', 'sample:1', 'New sample', 'WTSI', 9606, undef, 'Tate JG', undef, '2015-01-10T14:30:00', 'GAZ:00444180', 1, 'Homo sapiens', 'healthy', 'BTO:0000645', undef, 'serovar', undef, 'strain', undef, 'am1;S;50;WTSI', ];

is_deeply($values, $expected_values, 'got expected values for sample 1');

throws_ok { Schema->get_sample(99) } qr/no sample with that ID \(99\)/,
  'exception when retrieving fields for non-existent sample';

# using multiple sample IDs
my $set_of_values;
lives_ok { $set_of_values = Schema->get_samples(1,2) } 'got values for multiple samples';

# using a manifest ID
lives_ok { $set_of_values = Schema->get_samples($m->uuid) }
  'got samples using a manifest ID';

my $expected_set_of_values = [
  ['rda:2','sa:1','test sample','WTSI',9606,undef,'Tate JG','BSACID:1','2014-01-10T11:20:30','GAZ:00444180',1,'Homo sapiens','healthy','BTO:0000645',undef,'serovar',undef,'strain',undef,'am1;S;10,am2;I;20;WTSI'],
  ['rda:3','sa:1','test sample','WTSI',9606,undef,'Tate JG','BSACID:1','2014-01-10T11:20:30','GAZ:00444180',1,'Homo sapiens','healthy','BTO:0000645',undef,'serovar',undef,'strain',undef,'am1;S;10,am2;I;20;WTSI'],
];

is_deeply( $set_of_values, $expected_set_of_values, 'got expected set of field values' );

# generate a manifest from the DB and compare it to the one we used to load the
# data. Spoof the MD5, UUID and config filename
my $new_m = Schema->get_manifest($m->uuid);
$new_m->md5($m->md5);
$new_m->uuid($m->uuid);
$new_m->config->{config_file} = 't/data/01_manifest.conf';

is_deeply( $m, $new_m, 'manifest generated from the DB matches original' );

# test insert failure behaviour
$m->rows->[0]->[0] = 'rda:99';
$m->rows->[0]->[9] = undef;

# check for error messages in the manifest after a failure
throws_ok { Schema->load_manifest($m) } qr/the data in the manifest are not valid/,
  'got an exception when loading a manifest without a "location" value';

like( $m->row_errors->[0], qr/'location' is a required field/,
  'error in manifest shows "location" as a required field' );

done_testing;

