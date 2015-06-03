#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 29;
use Test::Exception;
use Test::DBIx::Class qw( :resultsets );

# see 01_load.t
fixtures_ok 'main', 'installed fixtures';
lives_ok { Schema->storage->dbh_do( sub { $_[1]->do('PRAGMA foreign_keys = ON') } ) }
  'successfully turned on "foreign_keys" pragma';

is( Assembly->count, 2, 'two assemblies loaded initially' );
is( File->count, 2, 'two files loaded initially' );

# load a valid file first
my $assembly;
lives_ok { $assembly = Assembly->load('/home/testuser/ERS111111_11111111111111111111111111111111_12345678-1234-1234-1234-1234567890AB.fa') }
  'assembly loaded successfully';

is( Assembly->count, 2, 'two assemblies loaded now' );
is( File->count, 3, 'three files loaded now' );

my $rs;
lives_ok { $rs = $assembly->get_files } 'retrieved files successfully';
is( $rs->count, 3, 'got three files for new assembly' );
is( $rs->first->version, 3, 'first file in resultset has correct version (3)' );

throws_ok { $assembly->get_file(-1) } qr/must be a positive integer/,
  "can't get a file with an invalid version number";

is $assembly->get_file(3)->version, 3, 'can get specific file version';

# load a new sample and an assembly for it
my $columns = {
  manifest_id              => '4162F712-1DD2-11B2-B17E-C09EFE1DC403',
  raw_data_accession       => 'data:2',
  sample_accession         => 'ERS222222',
  sample_description       => 'New sample',
  collected_at             => 'CAMBRIDGE',
  tax_id                   => 9606,
  scientific_name          => undef,
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
  antimicrobial_resistance => 'am1;S;50',
};

my $sample_id = Sample->load($columns);
Assembly->load('/home/testuser/ERS222222_22222222222222222222222222222222_12345678-1234-1234-1234-1234567890AB.fa');

# try deleting
lives_ok { $assembly->delete } 'delete works';
ok defined $assembly->deleted_at, 'deleted assembly';

# associated files should also be flagged as deleted
my $deleted_files = 0;
$deleted_files++ for $assembly->files->all;
is $deleted_files, 3, 'all assembly files have deleted_at set';

lives_ok { $rs = $assembly->get_files } 'retrieved live files successfully';
is( $rs->count, 0, 'got no live files for new assembly' );

lives_ok { $rs = $assembly->get_files(1) } 'retrieved deleted files successfully';
is( $rs->count, 3, 'got three deleted files for new assembly' );

is( $assembly->get_file(3), undef, 'got undef when trying to get deleted file' );
isa_ok( $assembly->get_file(3,1), 'Bio::HICF::Schema::Result::File', 'got row when explicitly getting a deleted file' );

# check error catching
throws_ok { Assembly->load('/home/testuser/ERS111111_11111111111111111111111111111111_12345678-1234-1234-1234-1234567890AB.fa') }
  qr/failed to load file/,
  "can't load same file again";
is( Assembly->count, 2, 'still two assemblies loaded' );

throws_ok { Assembly->load('ERS333333_33333333333333333333333333333333_12345678-1234-1234-1234-1234567890AB.fa') }
  qr/must be a full path/,
  "can't load file without full path";

throws_ok { Assembly->load('/home/testuser/ERS333333_33333333333333333333333333333333_12345678-1234-1234-1234-1234567890AB') }
  qr/couldn't parse file path/,
  "can't load file without suffix";

throws_ok { Assembly->load('/home/testuser/333333_33333333333333333333333333333333_12345678-1234-1234-1234-1234567890AB') }
  qr/couldn't parse file path/,
  "can't load file with bad ERS number";

throws_ok { Assembly->load('/home/testuser/ERS333333_3.fa') }
  qr/can't find ERS number, MD5 and UUID in filename/,
  "can't load file with bad MD5";

throws_ok { Assembly->load('/home/testuser/ERS333333_33333333333333333333333333333333_1.fa') }
  qr/can't find ERS number, MD5 and UUID in filename/,
  "can't load file with bad UUID";

throws_ok { Assembly->load('/home/testuser/ERS999999_99999999999999999999999999999999_12345678-1234-1234-1234-1234567890AB.fa') }
  qr/no such sample/,
  "can't load assembly for non-existent sample";

done_testing;

