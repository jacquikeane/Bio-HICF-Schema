
use strict;
use warnings;

use Test::More;
use File::Temp;
use Test::DBIx::Class qw( :resultsets );
use Test::CacheFile;
use Test::Exception;
use Archive::Tar;

use Bio::Metadata::Checklist;
use Bio::Metadata::Reader;

# set up the testing environment

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
my $tar = Archive::Tar->new('.cached_test_files/taxdump.tar.gz');
$tar->extract_file( 'names.dmp', '.cached_test_files/names.dmp' );

#-------------------------------------------------------------------------------

# make sure we can retrieve samples and manifests

SKIP: {
  skip 'sample/manifest retrieval', 11 if $ENV{SKIP_RETRIEVAL_TESTS};

  my $c = Bio::Metadata::Checklist->new( config_file => 't/data/01_checklist.conf' );
  my $r = Bio::Metadata::Reader->new( checklist => $c );
  my $m = $r->read_csv('t/data/01_manifest.csv');

  my @sample_ids;
  lives_ok { @sample_ids = Schema->load_manifest($m) } 'loading valid manifest works';

  # using a single sample ID
  my $values;
  lives_ok { $values = Schema->get_sample_values(1) } 'got field values for sample ID 1';

  my $expected_values = [ 'data:1', 'ERS111111', 'New sample', 'CAMBRIDGE', 9606, undef, 'Tate JG', undef, 1428658943, 'GAZ:00444180', 1, 'Homo sapiens', 'healthy', 'BTO:0000645', 'inpatient', undef, 'serovar', undef, 'strain', undef, 'am1;S;50;WTSI', ];

  is_deeply($values, $expected_values, 'got expected values for sample 1');

  throws_ok { Schema->get_sample_values(99) } qr/no sample with that ID \(99\)/,
    'exception when retrieving fields for non-existent sample';

  # using multiple sample IDs
  my $set_of_values;
  lives_ok { $set_of_values = Schema->get_samples_values(1,2) } 'got values for multiple samples';

  # using a manifest ID
  lives_ok { $set_of_values = Schema->get_samples_values($m->uuid) }
    'got samples using a manifest ID';

  my $expected_set_of_values = [
    ['rda:2','ERS333333','test sample','CAMBRIDGE',9606,undef,'Tate JG','BSACID:1','2014-01-10T11:20:30','GAZ:00444180',1,'Homo sapiens','healthy','BTO:0000645','inpatient',undef,'serovar',undef,'strain',undef,'am1;S;10,am2;I;20;WTSI'],
    ['rda:3','ERS444444','test sample','CAMBRIDGE',9606,undef,'Tate JG','BSACID:1','2014-01-10T11:20:30','GAZ:00444180',1,'Homo sapiens','healthy','BTO:0000645','inpatient',undef,'serovar',undef,'strain',undef,'am1;S;le10,am2;I;20;WTSI'],
  ];

  is_deeply( $set_of_values, $expected_set_of_values, 'got expected set of field values' );

  # generate a manifest from the DB and compare it to the one we used to load the
  # data. Spoof the MD5, UUID and config filename
  my $new_m = Schema->get_manifest($m->uuid);
  $new_m->md5($m->md5);
  $new_m->uuid($m->uuid);
  $new_m->checklist->{config_file} = 't/data/01_checklist.conf';

  is_deeply( $m, $new_m, 'manifest generated from the DB matches original' );

  is( Schema->get_manifest('x'), undef, '"get_manifest" returns undef with bad manifest ID' );

  # test insert failure behaviour
  $m->rows->[0]->[0] = 'rda:99';
  $m->rows->[0]->[9] = undef;

  # check for error messages in the manifest after a failure
  throws_ok { Schema->load_manifest($m) } qr/the data in the manifest are not valid/,
    'got an exception when loading a manifest without a "location" value';

  like( $m->row_errors->[0], qr/'location' is a required field/,
    'error in manifest shows "location" as a required field' );
}

#-------------------------------------------------------------------------------

# adding antimicrobials

SKIP: {
  skip 'antimicrobial loading', 5 if $ENV{SKIP_AM_LOADING_TESTS};

  is( Antimicrobial->count, 2, 'found 2 antimicrobial names before load' );
  lives_ok { Schema->load_antimicrobial('am3') } 'adding new antimicrobial succeeds';
  is( Antimicrobial->count, 3, 'found 3 antimicrobial names after load' );

  throws_ok { Schema->load_antimicrobial('am#') } qr/Not a valid antimicrobial compound name/,
    'got expected error message with invalid compound name';
  is( Antimicrobial->count, 3, 'still 3 rows in table after load failure' );
}

#-------------------------------------------------------------------------------

# adding antimicrobial resistance test results

SKIP: {
  skip 'antimicrobial resistance result loading', 3 if $ENV{SKIP_AMR_LOADING_TESTS};

  my %amr = (
    sample_id         => 1,
    name              => 'am1',
    susceptibility    => 'R',
    mic               => 10,
    diagnostic_centre => 'Peru',
  );
  lives_ok { Schema->load_antimicrobial_resistance(%amr) }
    'no error when adding a new valid amr';

  $amr{sample_id} = 99;
  throws_ok { Schema->load_antimicrobial_resistance(%amr) }
    qr/both the antimicrobial and the sample/,
    'error when adding an amr with a missing sample ID';

  %amr = (
    sample_id         => 1,
    name              => 'am1',
    susceptibility    => 'S',
    mic               => 50,
    equality          => 'eq',
    diagnostic_centre => 'WTSI',
  );
  throws_ok { Schema->load_antimicrobial_resistance(%amr) }
    qr/already exists/,
    'error when adding an amr that already exists';
}

#-------------------------------------------------------------------------------

# ontologies

SKIP: {
  skip 'ontology loading', 7, if $ENV{SKIP_ONTOLOGY_TESTS};

  throws_ok { Schema->load_ontology( 'not a real ontology', 't/data/01_gaz.obo' ) }
    qr/Validation failed for 'Bio::Metadata::Types::OntologyName'/,
    'error when trying to load ontology into non-existent table';

  throws_ok { Schema->load_ontology( 'gazetteer', 'non-existent file' ) }
    qr/ontology file not found/,
    'error when trying to load a non-existent file';

  is( Gazetteer->count, 1, 'one row in ontology before load' );
  lives_ok { Schema->load_ontology( 'gazetteer', 't/data/01_gaz.obo' ) }
    'no error when loading valid ontology';
  is( Gazetteer->count, 13, '13 rows in ontology after load' );

  lives_ok { Schema->load_ontology( 'gazetteer', 't/data/01_gaz.obo', 5 ) }
    'no error when loading valid ontology';
  is( Gazetteer->count, 13, '13 rows in ontology after loading in multiple chunks' );
}

#-------------------------------------------------------------------------------

# external resource tracking

is( ExternalResource->count, 0, 'no resources before we begin' );
throws_ok { Schema->add_external_resource( {} ) } qr/one of the required/,
  'exception with missing fields';

my $resource = {
  name         => 'some resource',
  source       => 'http://www.sanger.ac.uk/',
  retrieved_at => DateTime->now,
  checksum     => 'dfb3f67b349077ab39babb6931858788',
};
lives_ok { Schema->add_external_resource($resource) } 'no exception with valid resource';
is( ExternalResource->count, 1, 'one resource after loading' );

$DB::single = 1;

done_testing;

