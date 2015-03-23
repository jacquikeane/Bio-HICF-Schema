#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
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
lives_ok { $assembly = Assembly->load_assembly('/home/testuser/ERS123456_123456789a123456789b123456789cdc.fa') }
  'assembly loaded successfully';

is( Assembly->count, 2, 'two assemblies loaded now' );
is( File->count, 3, 'three files loaded now' );

my $rs;
lives_ok { $rs = $assembly->get_files } 'retrieved files successfully';
is( $rs->count, 3, 'got three files for new assembly' );
is( $rs->first->version, 3, 'first file in resultset has correct version (3)' );

# check error catching
throws_ok { Assembly->load_assembly('/home/testuser/ERS123456_123456789a123456789b123456789cdc.fa') }
  qr/failed to load file/,
  "can't load same file again";
is( Assembly->count, 2, 'still two assemblies loaded' );

throws_ok { Assembly->load_assembly('ERS123456_123456789a123456789b123456789cdc.fa') }
  qr/must be a full path/,
  "can't load file without full path";

throws_ok { Assembly->load_assembly('/home/testuser/ERS123456_123456789a123456789b123456789cdc') }
  qr/couldn't parse file path/,
  "can't load file without suffix";

throws_ok { Assembly->load_assembly('/home/testuser/123456_123456789a123456789b123456789cdc') }
  qr/couldn't parse file path/,
  "can't load file with bad ERS number";

throws_ok { Assembly->load_assembly('/home/testuser/ERS123456_23456789a123456789b123456789cdc.fa') }
  qr/can't find ERS number and MD5 in filename/,
  "can't load file with bad MD5";

throws_ok { Assembly->load_assembly('/home/testuser/ERS999999_123456789a123456789b123456789cdc.fa') }
  qr/no such sample/,
  "can't load assembly for non-existent sample";

$DB::single = 1;

done_testing;

