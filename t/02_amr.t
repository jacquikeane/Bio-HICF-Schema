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
 'found expected pre-loaded values in amr table';

my $rs;
ok $rs = AntimicrobialResistance->search( { sample_id => 1 }, {} ),
  'search on amr table works';

is( $rs->count, 1, 'found expected row in amr table' );

my $amr = $rs->first;

is( $amr->get_amr_string, 'am1;S;50;WTSI', 'got expected amr string' );
$amr->diagnostic_centre(undef);
is( $amr->get_amr_string, 'am1;S;50', 'got expected amr string after removing diagnostic centre' );

#-------------------------------------------------------------------------------

# loading new antimicrobial compound names

is( Antimicrobial->count, 2, 'found 2 antimicrobial before load' );
lives_ok { Antimicrobial->load_antimicrobial('am3') } 'loading "am3" succeeds';
is( Antimicrobial->count, 3, 'found 3 antimicrobials after load' );

lives_ok { Antimicrobial->load_antimicrobial('am3') } 'loading "am3" again succeeds';
is( Antimicrobial->count, 3, 'found 3 antimicrobials after loading duplicate' );

throws_ok { Antimicrobial->load_antimicrobial('am#') } qr/Not a valid antimicrobial compound name/,
  'loading invalid antimicrobial name fails';
is( Antimicrobial->count, 3, 'found 3 antimicrobials after failed load' );

#-------------------------------------------------------------------------------

# loading new antimicrobial resistance test results

my %amr_params = (
  sample_id         => 1,
  name              => 'am3',
  susceptibility    => 'R',
  mic               => 10,
  diagnostic_centre => 'Peru',
);
lives_ok { AntimicrobialResistance->load_antimicrobial_resistance(%amr_params) }
  'no error when adding a new valid amr';

$amr_params{sample_id} = 99;
throws_ok { AntimicrobialResistance->load_antimicrobial_resistance(%amr_params) }
  qr/both the antimicrobial and the sample/,
  'error when adding an amr with a missing sample ID';

$amr_params{sample_id} = 1;
$amr_params{name}      = 'x';
throws_ok { AntimicrobialResistance->load_antimicrobial_resistance(%amr_params) }
  qr/both the antimicrobial and the sample/,
  'error when adding an amr with a missing compound name';

%amr_params = (
  sample_id         => 1,
  name              => 'am1',
  susceptibility    => 'S',
  mic               => 50,
  diagnostic_centre => 'WTSI',
);
throws_ok { AntimicrobialResistance->load_antimicrobial_resistance(%amr_params) }
  qr/already exists/,
  'error when adding an amr that already exists';

$DB::single = 1;

done_testing();

