#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use File::Temp;
use DBIx::RunSQL;
use List::MoreUtils qw( mesh );
use Test::CacheFile;
use Bio::Metadata::Config;
use Bio::Metadata::Manifest;

use_ok( 'Bio::HICF::Schema' );

# set up a file-based test SQLite DB
my $fh = File::Temp->new;
$fh->close;

my $dsn;
if ( $ENV{SQLITE_FILE_DB} ) {
  $dsn = 'dbi:SQLite:dbname=' . $fh->filename;
  diag 'using file-based SQLite DB at ' . $fh->filename . ' (set $ENV{SQLITE_FILE_DB} to FALSE to use in-memory DB)';
}
else {
  $dsn = 'dbi:SQLite:dbname=:memory:';
  diag 'using in-memory SQLite DB (set $ENV{SQLITE_FILE_DB} to true to use file-based DB)';
}

my $schema = Bio::HICF::Schema->connect(
  $dsn, '', '',
  {
    sqlite_unicode => 1,
  }
);

ok $schema, 'connected to test DB successfully';

lives_ok { $schema->deploy } 'deployed schema successfully';

# INSERTs to set up the tables
my @setup_statements = (
  q|PRAGMA foreign_keys = ON|, # have to turn on foreign keys explicitly for SQLite
  q|INSERT INTO `antimicrobial` (`name`, `created_at`) VALUES ('am1', date('now')), ('am2', date('now'))|,
  q|INSERT INTO `gazetteer` (`gaz_id`, `description`) VALUES ('GAZ:00444180', 'Hinxton')|,
  q|INSERT INTO `brenda` (`brenda_id`, `description`) VALUES ('BTO:0000645', 'Lung')|,
  q|INSERT INTO `taxonomy` (`ncbi_taxid`) VALUES (9606)|,
  q|INSERT INTO `envo` (`envo_id`, `description`) VALUES ('ENVO:00002148', 'coarse beach sand')|,
  q|INSERT INTO `manifest` (`manifest_id`,`md5`,`ticket`,`created_at`) VALUES ('4162F712-1DD2-11B2-B17E-C09EFE1DC403','6df23dc03f9b54cc38a0fc1483df6e21',NULL,datetime('now'))|,
  q|INSERT INTO `sample` (`manifest_id`, `raw_data_accession`, `sample_accession`, `sample_description`, `collected_at`, `ncbi_taxid`, `scientific_name`, `collected_by`, `collection_date`, `location`, `host_associated`, `specific_host`, `host_disease_status`, `host_isolation_source`, `isolation_source`, `serovar`, `other_classification`, `strain`, `isolate`, `withdrawn`, `created_at`, `updated_at`, `deleted_at`) VALUES ('4162F712-1DD2-11B2-B17E-C09EFE1DC403', 'data:1', 'sample:1', 'New sample', 'WTSI', 9606, NULL, 'Tate JG', '2015-01-10T14:30:00', 'GAZ:00444180', 1, 'Homo sapiens', 'healthy', 'BTO:0000645', NULL, 'serovar', NULL, 'strain', NULL, NULL, '20141202T16:55:00', '20141202T16:55:00', NULL)|,
  q|INSERT INTO `antimicrobial_resistance` (`sample_id`, `antimicrobial_name`, `susceptibility`, `mic`, `diagnostic_centre`, `created_at`) VALUES (1,'am1','S',50,'WTSI',datetime('now'))|,
);

my $dbh_do = sub {
  my ( $storage, $dbh, @setup_statements ) = @_;
  foreach ( @setup_statements ) {
    $dbh->do($_);
  }
};

lives_ok { $schema->storage->dbh_do( $dbh_do, @setup_statements ) } 'no error when pre-loading DB';

my @sample_columns = (
  qw(
    raw_data_accession
    sample_accession
    sample_description
    collected_at
    ncbi_taxid
    scientific_name
    collected_by
    source
    collection_date
    location
    host_associated
    specific_host
    host_disease_status
    host_isolation_source
    isolation_source
    serovar
    other_classification
    strain
    isolate
    antimicrobial_resistance
  )
);

my @sample_data = (
  'rda:2',                 # raw_data_accession
  'sa:1',                  # sample_accession
  'test sample',           # sample_description
  'WTSI',                  # collected_at
  9606,                    # ncbi_taxid
  undef,                   # scientific_name
  'Tate JG',               # collected_by
  'BSACID:1',              # source
  '2014-01-10T11:20:30',   # collection_date
  'GAZ:00444180',          # location
  1,                       # host_associated
  'Homo sapiens',          # specific_host
  'healthy',               # host_disease_status
  'BTO:0000645',           # host_isolation_source
  undef,                   # isolation_source
  'serovar',               # serovar
  undef,                   # other_classification
  'strain',                # strain
  undef,                   # isolate
  undef,                   # amr
);

diag 'caching ontology files';
Test::CacheFile::cache( 'http://purl.obolibrary.org/obo/subsets/envo-basic.obo', 'envo-basic.obo' );
Test::CacheFile::cache( 'http://purl.obolibrary.org/obo/gaz.obo', 'gaz.obo' );
Test::CacheFile::cache( 'http://www.brenda-enzymes.info/ontology/tissue/tree/update/update_files/BrendaTissueOBO', 'bto.obo' );

my $c = Bio::Metadata::Config->new( config_file => 't/data/01_manifest.conf' );
my $r = Bio::Metadata::Reader->new( config => $c );
my $m = $r->read_csv('t/data/01_manifest.csv');

lives_ok { $schema->load_manifest($m) } 'loading valid manifest works';

my $sample_table = $schema->resultset('Sample');
my $amr_table = $schema->resultset('AntimicrobialResistance');
ok( $sample_table->find(2), 'found new sample row in table' );
is( $amr_table->search({},{})->count, 3, 'found expected number of antimicrobial resistance rows' );

my $existing_row = $sample_table->find(2);
isnt( $existing_row->created_at, undef, 'created_at not empty, as expected' );
is( $existing_row->updated_at, undef, '"updated_at" empty as expected before update' );

diag 'SQLite DB at ' . $fh->filename;

$DB::single = 1;

done_testing();

__END__

# make sure the DB state is as we expect before updating
$row = $sample_rs->find(4);
is( $row->updated_at, undef, 'updated_at empty, as expected' );

# update a row
$sample_hash{raw_data_accession} = 'rda:2';
lives_ok { $sample_rs->load( \%sample_hash ) } 'updating works';

$row = $sample_rs->find(4);
is( $row->raw_data_accession, 'rda:2', 'updated accession as expected' );
isnt( $row->updated_at, undef, 'updated_at now as expected' );

# test insert/update failure behaviour
$sample_hash{location} = undef;
throws_ok { $sample_rs->load( \%sample_hash ) } qr/NOT NULL constraint failed: sample\.location/, 'got an exception when updating without a "location" value';

# test handling of antimicrobial resistance data
$sample_hash{location}  = 'GAZ:00444180'; # reset to valid value
$sample_hash{sample_id} = 5;
$sample_hash{amr}       = 'am1;R;50;China, non-existent-am;R;10';

dies_ok { $sample_rs->load( \%sample_hash ) } 'exception when violating a foreign key constraint';

$sample_hash{amr}       = 'am1;R;50;China, am2;R;10';

my $amr_rs = $schema->resultset('AntimicrobialResistance');
is( $amr_rs->search( {}, {} )->count, 1, 'expected number of rows in amr table before insert' );
lives_ok { $sample_rs->load( \%sample_hash ) } 'no error when loading antimicrobial resistance data';
is( $amr_rs->search( {}, {} )->count, 3, 'expected number of rows in amr table after insert' );

diag 'SQLite DB filename: ' . $fh->filename
  if $ENV{SQLITE_FILE_DB};
$DB::single = 1;

done_testing();

