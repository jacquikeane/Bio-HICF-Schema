#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 109;
use Test::Exception;
use Test::DBIx::Class qw( :resultsets );
use DateTime;

# see 01_load.t
fixtures_ok 'main', 'installed fixtures';
lives_ok { Schema->storage->dbh_do( sub { $_[1]->do('PRAGMA foreign_keys = ON') } ) }
  'successfully turned on "foreign_keys" pragma';

my $expected_values = [
  'data:1',
  'ERS111111',
  'donor1',
  'New sample',
  'CAMBRIDGE',
  9606,
  undef,
  'Tate JG',
  undef,
  1428658943,
  'GAZ:00444180',
  1,
  'Homo sapiens',
  'healthy',
  'BTO:0000645',
  'inpatient',
  undef,
  'serovar',
  undef,
  'strain',
  undef,
  'am1;S;50;WTSI',
];

my $expected_hash = {
  antimicrobial_resistance => 'am1;S;50;WTSI',
  collected_by             => 'Tate JG',
  collection_date          => 1428658943,
  donor_id                 => 'donor1',
  host_associated          => 1,
  host_disease_status      => 'healthy',
  host_isolation_source    => 'BTO:0000645',
  isolate                  => undef,
  isolation_source         => undef,
  location                 => 'GAZ:00444180',
  other_classification     => undef,
  patient_location         => 'inpatient',
  raw_data_accession       => 'data:1',
  sample_accession         => 'ERS111111',
  sample_description       => 'New sample',
  scientific_name          => undef,
  serovar                  => 'serovar',
  source                   => undef,
  specific_host            => 'Homo sapiens',
  strain                   => 'strain',
  submitted_by             => 'CAMBRIDGE',
  tax_id                   => 9606,
};

my $sample;
lives_ok { $sample = Sample->find(1) } 'retrieved row for sample ID 1';

my $values;
lives_ok { $values = $sample->field_values } 'got field values for sample ID 1';
is_deeply($values, $expected_values, 'got expected values for sample 1');

lives_ok { $values = $sample->fields } 'got field values hash for sample ID 1';
is_deeply($values, $expected_hash, 'got expected values for sample 1');

my $manifest_id       = '4162F712-1DD2-11B2-B17E-C09EFE1DC403';
my $other_manifest_id = '0162F712-1DD2-11B2-B17E-C09EFE1DC403';
my $columns = {
  antimicrobial_resistance => 'am1;I;25',
  collected_by             => 'Tate JG',
  collection_date          => 1428658943,
  donor_id                 => 'donor2',
  host_associated          => 1,
  host_disease_status      => 'healthy',
  host_isolation_source    => 'BTO:0000645',
  isolate                  => undef,
  isolation_source         => undef,
  location                 => 'GAZ:00444180',
  manifest_id              => $manifest_id,
  other_classification     => undef,
  patient_location         => 'inpatient',
  raw_data_accession       => 'data:2',
  sample_accession         => 'ERS123456',
  sample_description       => 'New sample',
  scientific_name          => undef,
  serovar                  => 'serovar',
  source                   => undef,
  specific_host            => 'Homo sapiens',
  strain                   => 'strain',
  submitted_by             => 'CAMBRIDGE',
  tax_id                   => 9606,
};

my $sample_id;
lives_ok { $sample_id = Sample->load($columns) } 'row loads ok';

is( $sample_id, 2, '"load" returns expected sample_id for new row' );
is( AntimicrobialResistance->count, 2, 'found expected row in antimicrobial_resistance table' );

is( Sample->all_rs->count, 2, '"all" returns a ResultSet with 2 rows' );
my $samples = Sample->all_rs;
is( $samples->next->sample_id, 1, 'got first sample via "all"' );
is( $samples->next->sample_id, 2, 'got second sample via "all"' );
is( $samples->next, undef, 'got expected number of samples via "all"' );

# load the same sample again
throws_ok { $sample_id = Sample->load($columns) } qr/(UNIQUE constraint failed|not unique)/,
  'error when loading same sample with same manifest ID';
$columns->{manifest_id} = $other_manifest_id;
lives_ok { $sample_id = Sample->load($columns) } 'row loads ok a second time';

# after loading the same sample a second time we should have two rows, with the
# older one having a value for "deleted_at"
my $rs = Sample->search( { sample_accession => 'ERS123456' } );
is( $rs->count, 2, 'got two samples for accession' );

my @samples = $rs->all;
my $deleted = $samples[0];
my $live    = $samples[1];

is $deleted->sample_id, 2, 'got expected sample ID for deleted sample';
is $live->sample_id,    3, 'got expected sample ID for live sample';

is $deleted->is_deleted, 1, '"is_deleted works for deleted row';
is $live->is_deleted,    0, '"is_deleted works for live row';

is Sample->all_rs->count, 2, '"all" returns RS with 2 rows';
is Sample->all_rs(1)->count, 3, '"all" with include_deleted flag returns RS with 3 rows';

my $deleted_sample = Sample->search( { 'me.deleted_at' => { '!=', undef } } );
my $deleted_amrs   = $deleted_sample->search_related(
                       'antimicrobial_resistances',
                       { 'me.deleted_at' => { '!=', undef } },
                       {}
                     );
is $deleted_amrs->count, 1, 'got expected deleted AMR';

# reset the sample accession so we can load further sample metadata as new rows
$columns->{sample_accession} = 'ERS654321';

# check AMR
my @all_samples = Sample->all_rs(1);
is $all_samples[0]->has_amr, 1, 'first sample has AMR results';
is $all_samples[1]->has_amr, 0, 'second sample has no live AMR results';

# load another AMR result to make sure we get back multiple results from
# "get_amr"
AntimicrobialResistance->load(
  {
    sample_id      => 1,
    name           => 'am1',
    susceptibility => 'R',
    mic            => 10,
    equality       => 'le',
  }
);
my $amrs = Sample->find(1)->get_amr;
is $amrs->count, 2, 'found two AMR results for sample 1';
is( ( $amrs->all )[1]->mic, 10, 'got expected value for AMR' );

#-------------------------------------------------------------------------------

# check we can load data with "unknown" values

$columns->{collection_date} = 'not available: not collected';
lives_ok { $sample_id = Sample->load($columns) }
  'no error when loading data with "unknown" date';
$columns->{collection_date} = '2015-01-10T14:30:00';

my $s = Sample->find(4);

#---------------------------------------

# collection_date

is( $s->collection_date, 'not available: not collected', 'collection_date is expected unknown' );
lives_ok { $s->collection_date('obscured') }
  'no error setting collection_date to different, valid unknown';
throws_ok { $s->collection_date('invalid unknown value') }
  qr/not a valid date or 'unknown'/,
  'error setting collection_date to invalid unknown';
lives_ok { $s->collection_date(DateTime->now->epoch) }
  'no error setting collection_date to valid epoch time';

#---------------------------------------

# collection_date_dt

isa_ok $s->collection_date_dt, 'DateTime', 'collection_date_dt produces a DateTime';
throws_ok { $s->collection_date_dt('invalid unknown value') }
  qr/not unknown and can't/,
  'error setting collection_date_dt to invalid unknown';
lives_ok { $s->collection_date_dt('not available: not collected') }
  'no error setting collection_date_dt to a valid unknown';
is( $s->collection_date_dt, undef, 'collection_date_dt is undef when set to unknown' );
my $now = DateTime->now;
my $epoch = $now->epoch;
lives_ok { $s->collection_date_dt($now) }
  'no error setting collection_date_dt to a DateTime';

my $retrieved_now = $s->collection_date_dt;
is( "$retrieved_now", "$now", 'collection_date_dt returns expected DT when set to a valid time' );

lives_ok { $s->collection_date_dt($epoch) }
  'no error setting collection_date_dt to a valid epoch time';
$retrieved_now = $s->collection_date_dt;
is( "$retrieved_now", "$now", 'collection_date_dt returns expected DT when set using an epoch time' );

#---------------------------------------

# location

is( $s->location, 'GAZ:00444180', 'location set as expected' );
lives_ok { $s->location('obscured') }
  'no error setting location to valid unknown';
is( $s->location, 'obscured', 'location returns unknown value' );
throws_ok { $s->location('not a valid unknown') }
  qr/not a valid location or 'unknown'/,
  'error setting location to an invalid unknown';
throws_ok { $s->location('GAZ:12345678') }
  qr/can't find location in Gazetteer/,
  'error setting location to a not-found ontology term';
lives_ok { $s->location('GAZ:00444180') }
  'no error setting location to valid GAZ term';
is( $s->location, 'GAZ:00444180', 'location set as expected' );

#---------------------------------------

# host_associated

is( $s->host_associated, 1, 'host_associated set as expected' );

lives_ok { $s->host_associated(0) } 'no error setting host_associated to valid false (0)';
is( $s->host_associated, 0, 'host_associated set as expected' );
lives_ok { $s->host_associated('no') } 'no error setting host_associated to valid false (no)';
is( $s->host_associated, 0, 'host_associated set as expected' );
lives_ok { $s->host_associated('false') } 'no error setting host_associated to valid false (false)';
is( $s->host_associated, 0, 'host_associated set as expected' );

lives_ok { $s->host_associated(1) } 'no error setting host_associated to valid true (1)';
is( $s->host_associated, 1, 'host_associated set as expected' );
lives_ok { $s->host_associated('yes') } 'no error setting host_associated to valid false (yes)';
is( $s->host_associated, 1, 'host_associated set as expected' );
lives_ok { $s->host_associated('true') } 'no error setting host_associated to valid false (true)';
is( $s->host_associated, 1, 'host_associated set as expected' );

lives_ok { $s->host_associated('not available: not collected') } 'no error setting host_associated to valid unknown';
is( $s->host_associated, 'not available: not collected', 'host_associated set as expected' );

throws_ok { $s->host_associated('not a valid value') }
  qr/host_associated must be true or false/,
  'error setting host_associated to an invalid value';

#---------------------------------------

# specific_host

is( $s->specific_host, 'Homo sapiens', 'specific_host set as expected' );
lives_ok { $s->specific_host('Homo sapiens neanderthalensis') }
  'no error setting specific_host to different valid name';
is( $s->specific_host, 'Homo sapiens neanderthalensis', 'specific_host returns expected value' );
lives_ok { $s->specific_host('not available: not collected') }
  'no error setting specific_host to valid unknown';
is( $s->specific_host, 'not available: not collected', 'specific_host returns expected unknown value' );

throws_ok { $s->specific_host('not a valid unknown') }
  qr/not an accepted unknown and can't find/,
  'error setting specific_host to an invalid value';

#---------------------------------------

# host_disease_status

is( $s->host_disease_status, 'healthy', 'host_disease_status set as expected' );
lives_ok { $s->host_disease_status('carriage') }
  'no error setting host_disease_status to different valid term';
is( $s->host_disease_status, 'carriage', 'host_disease_status set as expected' );
lives_ok { $s->host_disease_status('not available: not collected') }
  'no error setting host_disease_status to valid unknown';
is( $s->host_disease_status, 'not available: not collected', 'host_disease_status returns expected unknown value' );

throws_ok { $s->host_disease_status('not a valid unknown') }
  qr/must be "healthy"/,
  'error setting host_disease_status to an invalid value';

#---------------------------------------

# host_isolation_source

is( $s->host_isolation_source, 'BTO:0000645', 'host_isolation_source set as expected' );
lives_ok { $s->host_isolation_source('obscured') }
  'no error setting host_isolation_source to valid unknown';
is( $s->host_isolation_source, 'obscured', 'host_isolation_source returns unknown value' );
throws_ok { $s->host_isolation_source('not a valid unknown') }
  qr/not a valid Brenda ontology term/,
  'error setting host_isolation_source to an invalid unknown';
throws_ok { $s->host_isolation_source('BTO:1234567') }
  qr/can't find host_isolation_source in Brenda/,
  'error setting host_isolation_source to a not-found ontology term';
lives_ok { $s->host_isolation_source('BTO:0000645') }
  'no error setting host_isolation_source to valid Brenda term';
is( $s->host_isolation_source, 'BTO:0000645', 'host_isolation_source set as expected' );

#---------------------------------------

# patient_location

is( $s->patient_location, 'inpatient', 'patient_location set as expected' );
lives_ok { $s->patient_location('community') }
  'no error setting patient_location to different valid term';
is( $s->patient_location, 'community', 'patient_location set as expected' );
lives_ok { $s->patient_location('not available: not collected') }
  'no error setting patient_location to valid unknown';
is( $s->patient_location, 'not available: not collected', 'patient_location returns expected unknown value' );

throws_ok { $s->patient_location('not a valid unknown') }
  qr/must be "inpatient"/,
  'error setting patient_location to an invalid value';

#---------------------------------------

# isolation_source

is( $s->isolation_source, undef, 'isolation_source set as expected' );
lives_ok { $s->isolation_source('obscured') }
  'no error setting isolation_source to valid unknown';
is( $s->isolation_source, 'obscured', 'isolation_source returns unknown value' );
throws_ok { $s->isolation_source('not a valid unknown') }
  qr/not a valid EnvO ontology term/,
  'error setting isolation_source to an invalid unknown';
throws_ok { $s->isolation_source('ENVO:12345678') }
  qr/can't find isolation_source in EnvO/,
  'error setting isolation_source to a not-found ontology term';
lives_ok { $s->isolation_source('ENVO:00002148') }
  'no error setting isolation_source to valid EnvO term';
is( $s->isolation_source, 'ENVO:00002148', 'isolation_source set as expected' );

#-------------------------------------------------------------------------------

# test errors

# put the GAZ term back
$columns->{location} = 'GAZ:00444180';

# reset the manifest ID to the original value
$columns->{manifest_id} = $manifest_id;

$columns->{antimicrobial_resistance} = 'am1;X;50';
throws_ok { Sample->load($columns) } qr/Not a valid antimicrobial resistance test result/,
  "error loading invalid amr";
$columns->{antimicrobial_resistance} = 'am1;S;50';

$columns->{raw_data_accession} = 'data:3';
$columns->{scientific_name}    = 'Not a real species';
throws_ok { Sample->load($columns) } qr/not found for scientific name/,
  "error loading when tax ID and scientific name don't match";
is( Sample->count, 4, 'no rows loaded' );

$columns->{tax_id}          = 0;
$columns->{scientific_name} = 'Homo sapiens';
throws_ok { Sample->load($columns) } qr/not found for taxonomy ID/,
  "error loading when tax ID and scientific name don't match";
is( Sample->count, 4, 'no rows loaded' );

$columns->{tax_id}          = 63221;
$columns->{scientific_name} = 'Homo sapiens';
throws_ok { Sample->load($columns) } qr/taxonomy ID \(63221\) and scientific name \(Homo sapiens\) do not match/,
  "error loading when tax ID and scientific name don't match";
is( Sample->count, 4, 'no rows loaded' );

$columns->{tax_id}   = 9606;
$columns->{location} = 'not a gaz term';
throws_ok { Sample->load($columns) } qr/term in 'location' \(not a gaz term\) is not found/,
  "error loading when gazetteer term isn't found";
is( Sample->count, 4, 'no rows loaded' );

$columns->{location}              = 'GAZ:00444180';
$columns->{host_isolation_source} = 'not a bto term';
throws_ok { Sample->load($columns) } qr/term in 'host_isolation_source' \(not a bto term\) is not found/,
  "error loading when BRENDA term isn't found";
is( Sample->count, 4, 'no rows loaded' );

$columns->{host_isolation_source} = 'BTO:0000645';
$columns->{isolation_source}      = 'not an envo term';
throws_ok { Sample->load($columns) } qr/term in 'isolation_source' \(not an envo term\) is not found/,
  "error loading when EnvO term isn't found";
is( Sample->count, 4, 'no rows loaded' );

$DB::single = 1;

done_testing();


