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

my @sample_ids;
lives_ok { @sample_ids = Manifest->load($m) } 'loading valid manifest works';

is_deeply( \@sample_ids, [ 2, 3 ], 'got expected sample_ids from "load_manifest"' );

ok my $sample = Sample->find(2), 'found new sample';
is( AntimicrobialResistance->search({},{})->count, 5, 'found expected number of antimicrobial resistance rows' );

is_fields [ 'raw_data_accession' ], $sample, [ 'rda:2' ], 'new sample row has expected values';

is( $sample->antimicrobial_resistances->count, 2, 'new sample has 2 amr rows' );
is( $sample->antimicrobial_resistances->first->get_column('antimicrobial_name'), 'am1', 'new sample has expected antimicrobial_name' );

done_testing;

