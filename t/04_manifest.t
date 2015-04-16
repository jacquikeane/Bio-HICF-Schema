#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::DBIx::Class qw( :resultsets );

use Bio::Metadata::Checklist;
use Bio::Metadata::Reader;

fixtures_ok 'main', 'installed fixtures';
lives_ok { Schema->storage->dbh_do( sub { $_[1]->do('PRAGMA foreign_keys = ON') } ) }
  'successfully turned on "foreign_keys" pragma';

my $c = Bio::Metadata::Checklist->new( config_file => 't/data/04_checklist.conf' );
my $r = Bio::Metadata::Reader->new( checklist => $c );
my $m = $r->read_csv('t/data/04_manifest.csv');

my $manifest_row;
lives_ok { $manifest_row = Manifest->load($m) } 'loading valid manifest works';
isa_ok $manifest_row, 'Bio::HICF::Schema::Result::Manifest';

my @samples;
lives_ok { @samples = $manifest_row->get_samples }
  '"get_samples" succeeds in array context';
is scalar @samples, 2, 'got two sample rows';
is $samples[0]->sample_id, 2, 'first sample has expected ID';
is $samples[1]->sample_id, 3, 'second sample has expected ID';

my $samples;
lives_ok { $samples = $manifest_row->get_samples }
  '"get_samples" succeeds in scalar context';
isa_ok $samples, 'DBIx::Class::ResultSet';
is $samples->count, 2, 'resultset has expected number of rows (2)';

my @sample_ids;
lives_ok { @sample_ids = $manifest_row->get_sample_ids } 'got sample IDs from row';
is_deeply( \@sample_ids, [ 2, 3 ], 'got expected sample_ids from "get_sample_ids"' );

ok my $sample = Sample->find(2), 'found new sample';
is( AntimicrobialResistance->search({},{})->count, 5, 'found expected number of antimicrobial resistance rows' );

is_fields [ 'raw_data_accession' ], $sample, [ 'rda:2' ], 'new sample row has expected values';

is( $sample->antimicrobial_resistances->count, 2, 'new sample has 2 amr rows' );
is( $sample->antimicrobial_resistances->first->get_column('antimicrobial_name'), 'am1', 'new sample has expected antimicrobial_name' );

# load a second manifest so we can check deletion behaviour
$m = $r->read_csv('t/data/04_manifest_2.csv');
@sample_ids = Manifest->load($m);

$manifest_row = Manifest->find($m->uuid);
isa_ok( $manifest_row, 'Bio::HICF::Schema::Result::Manifest' );

# TODO add tests to make sure that the samples for the manifest are flagged as deleted,
# TODO and also the AMR records for those samples

lives_ok { $manifest_row->delete } 'deleting manifest succeeds';
isnt $manifest_row->deleted_at, undef, 'manifest is flagged as deleted';
isnt $manifest_row->samples->first->deleted_at, undef, 'sample is flagged as deleted';
isnt $manifest_row->samples->first->antimicrobial_resistances->first->deleted_at,
  'AMR is flagged as deleted';

$DB::single = 1;

done_testing;

  # # using a manifest ID
  # my $set_of_values; lives_ok { $set_of_values =
  #   Schema->get_samples_values($m->uuid) } 'got samples using a manifest ID';
  #
  # my $expected_set_of_values = [ ['rda:2','ERS333333','test
  #     sample','CAMBRIDGE',9606,undef,'Tate
  #     JG','BSACID:1','2014-01-10T11:20:30','GAZ:00444180',1,'Homo
  #     sapiens','healthy','BTO:0000645','inpatient',undef,'serovar',undef,'strain',undef,'am1;S;10,am2;I;20;WTSI'],
  #     ['rda:3','ERS444444','test sample','CAMBRIDGE',9606,undef,'Tate
  #       JG','BSACID:1','2014-01-10T11:20:30','GAZ:00444180',1,'Homo
  #       sapiens','healthy','BTO:0000645','inpatient',undef,'serovar',undef,'strain',undef,'am1;S;le10,am2;I;20;WTSI'],
  #       ];
  #
  # is_deeply( $set_of_values, $expected_set_of_values, 'got expected set of
  # field values' );
  #
