#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::DBIx::Class qw( :resultsets );

# load the pre-requisite data and THEN turn on foreign keys
fixtures_ok 'main', 'installed fixtures';

lives_ok { Schema->storage->dbh_do( sub { $_[1]->do('PRAGMA foreign_keys = ON') } ) } 'successfully turned on "foreign_keys" pragma';

is_fields [ qw( antimicrobial_name susceptibility mic diagnostic_centre ) ],
 AntimicrobialResistance,
 [ [ 'am1', 'S', 50, 'WTSI' ] ],
 'found expected values in amr table';

my $rs;
ok $rs = AntimicrobialResistance->search( { sample_id => 1 }, {} ),
  'search on amr table works';

is( $rs->count, 1, 'found 1 row in amr table' );

my $amr = $rs->first;

is( $amr->get_amr_string, 'am1;S;50;WTSI', 'got expected amr string' );
$amr->diagnostic_centre(undef);
is( $amr->get_amr_string, 'am1;S;50', 'got expected amr string after removing diagnostic centre' );

$DB::single = 1;

done_testing();

