
use strict;
use warnings;

use Test::More tests => 63;
use File::Temp;
use Test::DBIx::Class qw( :resultsets );
use Test::Exception;
use Archive::Tar;
use Data::UUID;

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

#-------------------------------------------------------------------------------

# make sure we can retrieve samples and manifests

SKIP: {
  skip 'sample/manifest retrieval', 11 if $ENV{SKIP_RETRIEVAL_TESTS};

  my $c = Bio::Metadata::Checklist->new( config_file => 't/data/01_checklist.conf' );
  my $r = Bio::Metadata::Reader->new( checklist => $c );
  my $m = $r->read_csv('t/data/01_manifest.csv');

  # check loading shortcuts on the schema; load a manifest and an assembly file
  lives_ok { Schema->load_manifest($m) } 'loading valid manifest works';
  lives_ok { Schema->load_assembly('/home/testuser/ERS111111_123456789012345678901234567890ab_12345678-1234-1234-1234-1234567890ab.fa') } 'loading an assembly works';

  # retrieve a manifest row
  my $retrieved_manifest_row;
  lives_ok { $retrieved_manifest_row = Schema->get_manifest($m->uuid) }
    '"get_manifest" lives';
  isa_ok $retrieved_manifest_row, 'Bio::HICF::Schema::Result::Manifest';

  # retrieve a manifest object
  my $retrieved_manifest_object;
  lives_ok { $retrieved_manifest_object = Schema->get_manifest_object($m->uuid) }
    '"get_manifest_object" lives';
  isa_ok $retrieved_manifest_object, 'Bio::Metadata::Manifest';

  # generate a manifest from the DB and compare it to the one we used to load the
  # data. Spoof the MD5, UUID and config filename
  my $new_m = Schema->get_manifest_object($m->uuid);
  $new_m->md5($m->md5);
  $new_m->uuid($m->uuid);
  $new_m->checklist->{config_file} = 't/data/01_checklist.conf';
  $new_m->_set_fh($m->_fh);
  $new_m->_set_csv($m->_csv);

  is_deeply( $m, $new_m, 'manifest generated from the DB matches original' );

  throws_ok { Schema->get_manifest_object('x') }
    qr/not a valid manifest ID/,
    '"get_manifest_object" throws an exception with bad manifest ID';

  # load a new version of one of the samples

  # this manifest is pre-loaded as a fixture
  my $other_manifest_id = '0162F712-1DD2-11B2-B17E-C09EFE1DC403';

  my $duplicate_row = {
    manifest_id              => $other_manifest_id,
    raw_data_accession       => 'rda:2',       #\_ these two rows are the ones that
    sample_accession         => 'ERS333333',   #/  determine if it's a duplicate
    sample_description       => 'New sample',
    collected_at             => 'CAMBRIDGE',
    tax_id                   => 9606,
    scientific_name          => 'Homo sapiens',
    collected_by             => 'Tate JG',
    source                   => undef,
    collection_date          => 1428658943,
    location                 => 'GAZ:00444180',
    host_associated          => 1,
    specific_host            => 'Homo sapiens',
    host_disease_status      => 'healthy',
    host_isolation_source    => 'BTO:0000645',
    patient_location         => 'inpatient',
    isolation_source         => undef,
    serovar                  => 'serovar',
    other_classification     => undef,
    strain                   => 'strain',
    isolate                  => undef,
    antimicrobial_resistance => 'am1;I;25',
  };
  Sample->load($duplicate_row);

  # retrieve all versions of a sample using a sample accession
  my @samples;
  lives_ok { @samples = Schema->get_sample_versions_by_accession('ERS333333') }
    'got sample versions using accession';
  is scalar @samples, 2, 'got expected number of samples (2)';

  # same but for a sample with only a single version
  lives_ok { @samples = Schema->get_sample_versions_by_accession('ERS444444') }
    'got sample with a single version using accession';
  is scalar @samples, 1, 'got expected number of samples (1)';

  # check it works in scalar context too
  my $sample;
  lives_ok { $sample = Schema->get_sample_versions_by_accession('ERS444444') }
    'got single sample version using accession';

  # retrieve latest version of a sample using a sample accession
  lives_ok { $sample = Schema->get_sample_by_accession('ERS333333') }
    'got latest sample version using accession';
  is $sample->sample_id, 4, 'sample has correct ID (4)';

  # retrieve a sample using a sample ID
  lives_ok { $sample = Schema->get_sample_by_id(2) }
    'got sample using id';
  is $sample->sample_accession, 'ERS333333', 'sample has correct accession (ERS333333)';

  # retrieve all samples
  my $all_samples_rs;
  lives_ok { $all_samples_rs = Schema->get_all_samples } 'ran get_all_samples successfully';
  is $all_samples_rs->count, 3, 'got expected number of samples';

  lives_ok { $all_samples_rs = Schema->get_all_samples(1) } 'ran get_all_samples successfully with $include_deleted set true';
  is $all_samples_rs->count, 4, 'got expected number of samples';

  # retrieve samples for a specified organism
  my $samples_for_organism_rs;
  lives_ok { $samples_for_organism_rs = Schema->get_samples_from_organism(9606) }
    'call to get samples by tax ID succeeds';
  is $samples_for_organism_rs->count, 3, 'got three samples for 9606';
  my @found_sample_ids;
  push @found_sample_ids, $_->sample_id for $samples_for_organism_rs->all;
  is_deeply( \@found_sample_ids, [ 1, 3, 4], 'got expected samples' );

  lives_ok { $samples_for_organism_rs = Schema->get_samples_from_organism(9606, 1) }
    'call to get ALL (deleted and otherwise) samples by tax ID succeeds';
  is $samples_for_organism_rs->count, 4, 'got four samples for 9606';
  @found_sample_ids = ();
  push @found_sample_ids, $_->sample_id for $samples_for_organism_rs->all;
  is_deeply( \@found_sample_ids, [ 1, 2, 3, 4], 'got expected samples' );

  lives_ok { $samples_for_organism_rs = Schema->get_samples_from_organism('Homo sapiens') }
    'call to get samples by sci name succeeds';
  is $samples_for_organism_rs->count, 3, 'got three samples for "Homo sapiens"';

  # check missing/non-existent accession/ID
  throws_ok { Schema->get_sample_by_accession() }
    qr/must supply a sample accession/,
    'got error with missing accession';
  throws_ok { Schema->get_sample_by_id() }
    qr/must supply a sample ID/,
    'got error with missing ID';
  is Schema->get_sample_by_accession('ERS999999'), undef,
    '"get_sample_by_accession" returns undef with non-existent accession';
  is Schema->get_sample_by_id(999999), undef,
    '"get_sample_by_id" returns undef with non-existent id';

  # TODO make these tests reflect the reality described in the POD for
  # TODO get_samples_in_manifest...

  # check sample rows returned via a manifest
  my $samples_in_manifest;
  lives_ok { $samples_in_manifest = Schema->get_samples_in_manifest($m->uuid) }
    "'get_samples_in_manifest' successful";
  is $samples_in_manifest->count, 1, 'got expected 1 sample in resultset';
  is $samples_in_manifest->first->sample_accession, 'ERS444444',
    'sample has expected accession';

  lives_ok { $samples_in_manifest = Schema->get_samples_in_manifest($m->uuid, 1) }
    q('get_samples_in_manifest' successful with $included_deleted true);

  is( $samples_in_manifest->count, 2, 'got expected 2 samples in resultset' );
  is( $samples_in_manifest->first->sample_accession, 'ERS333333', 'first sample looks right' );
  is( $samples_in_manifest->next->sample_accession, 'ERS444444', 'second sample looks right' );

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

  # the might_have relationship from sample to gazetteer causes a foreign key
  # to be added to the sample table in the SQLite test database when it's
  # instantiated from the schema. That causes problems when we load ontologies,
  # because the first thing that method does is empty the ontology table, which
  # hits the foreign key constraint. The same problem doesn't exist in the live
  # database, because although there's a relationship in the schema definition,
  # it's not there in the MySQL instance.
  #
  # Although it's a bit hacky, we can just turn off foreign key constraints
  # before calling "load_ontology", which avoids the problem for this test
  Schema->storage->dbh_do( sub {
    my ( $storage, $dbh, @other_args ) = @_;
    $dbh->do( 'PRAGMA foreign_keys = OFF' );
  } );

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

