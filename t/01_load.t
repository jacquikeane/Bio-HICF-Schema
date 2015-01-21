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

  # 'dbi:SQLite:dbname=' . $fh->filename, '', '',
my $schema = Bio::HICF::Schema->connect(
  $dsn, '', '',
  {
    sqlite_unicode => 1,
  }
);

ok $schema, 'connected to test DB successfully';

lives_ok { $schema->deploy } 'successfully deployed schema';

# INSERTs to set up the tables
my @setup_statements = (
  q|PRAGMA foreign_keys = ON|,
  q|INSERT INTO `antimicrobial` (`name`, `created_at`) VALUES ('am1', date('now')), ('am2', date('now'))|,
  q|INSERT INTO `gazetteer` (`gaz_id`, `description`) VALUES ('GAZ:00444180', 'Hinxton')|,
  q|INSERT INTO `brenda` (`brenda_id`, `description`) VALUES ('BTO:0000645', 'Lung')|,
  q|INSERT INTO `taxonomy` (`ncbi_taxid`) VALUES (9606)|,
  q|INSERT INTO `envo` (`envo_id`, `description`) VALUES ('ENVO:00002148', 'coarse beach sand')|,
  q|INSERT INTO `sample` (`raw_data_accession`, `sample_accession`, `sample_description`, `collected_at`, `ncbi_taxid`, `scientific_name`, `collected_by`, `collection_date`, `location`, `host_associated`, `specific_host`, `host_disease_status`, `host_isolation_source`, `isolation_source`, `serovar`, `other_classification`, `strain`, `isolate`, `withdrawn`, `created_at`, `updated_at`, `deleted_at`) VALUES ('data:1', 'sample:1', 'New sample', 'WTSI', NULL, 'Homo sapiens', 'Tate JG', '2015-01-10T14:30:00', 'GAZ:00444180', 1, 'Homo sapiens', 'healthy', 'BTO:0000645', NULL, 'serovar', NULL, 'strain', NULL, NULL, '20141202T16:55:00', '20141202T16:55:00', NULL)|,
  q|INSERT INTO `antimicrobial_resistance` (`sample_id`, `antimicrobial_name`, `susceptibility`, `mic`, `diagnostic_centre`, `created_at`) VALUES (1,'am1','S',50,'WTSI',date('now'))|,
);

my $dbh_do = sub {
  my ( $storage, $dbh, @setup_statements ) = @_;
  foreach ( @setup_statements ) {
    $dbh->do($_);
  }
};

lives_ok { $schema->storage->dbh_do( $dbh_do, @setup_statements ) } 'no error when pre-loading DB';

# my @sample_columns = (
#   qw(
#     raw_data_accession
#     sample_accession
#     sample_description
#     collected_at
#     ncbi_taxid
#     scientific_name
#     collected_by
#     source
#     collection_date
#     location
#     host_associated
#     specific_host
#     host_disease_status
#     host_isolation_source
#     isolation_source
#     serovar
#     other_classification
#     strain
#     isolate
#     antimicrobial_resistance
#   )
# );

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
my $m = Bio::Metadata::Manifest->new( config => $c );

# add a couple of rows to the manifest. We need to make sure we create two
# distinct arrays though, because we're adding them by reference.
my @row_0 = @sample_data;
my @row_1 = @sample_data;

$row_1[0] = 'rda:3';
$row_1[19] = 'am1;S;10,am2;I;20;WTSI';

$m->add_rows( \@row_0, \@row_1 );

lives_ok { $schema->load_manifest($m) } 'loading valid manifest works';

my $sample_table = $schema->resultset('Sample');
my $amr_table = $schema->resultset('AntimicrobialResistance');
ok( $sample_table->find(2), 'found new sample row in table' );
is( $amr_table->search({},{})->count, 3, 'found expected number of antimicrobial resistance rows' );

$DB::single = 1;

done_testing();

__END__

my %sample_hash = mesh @sample_columns, @sample_data;

my $sample_rs = $schema->resultset('Sample');

# check we can load from an array, an array ref, or a hash ref
lives_ok { $sample_rs->load( @sample_data ) } 'loading from an array works';

my $row = $sample_rs->find(2);
isnt( $row->created_at, undef, 'created_at not empty, as expected' );

$sample_data[0] = 3;
lives_ok { $sample_rs->load( \@sample_data ) } 'loading from an array ref works';

$sample_hash{sample_id} = 4;
lives_ok { $sample_rs->load( \%sample_hash ) } 'loading from a hash ref works';

is( $sample_rs->search( {}, {} )->count, 4, 'got expected number of rows in database' );

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

