#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 18;
use Test::Exception;
use Test::DBIx::Class qw( :resultsets );

# see 01_load.t
fixtures_ok 'main', 'installed fixtures';
lives_ok { Schema->storage->dbh_do( sub { $_[1]->do('PRAGMA foreign_keys = ON') } ) }
  'successfully turned on "foreign_keys" pragma';

is( File->count, 2, 'two files loaded' );

# mock an Assembly object
{
  package MockAssembly;
  sub new {
    my ( $class, $rv ) = @_;
    bless { rv => $rv }, shift;
  }
  sub assembly_id { return shift->{rv} }
}
my $assembly = MockAssembly->new(1);

# load a valid file first
my $file;
lives_ok { $file = File->load($assembly, '/home/testuser/ERS111111_123456789a123456789b123456789cdc_12345678-1234-1234-1234-1234567890ab.fa') }
  'file loaded successfully';

is( File->count, 3, 'three files loaded now' );
is( $file->version, 3, 'new File has correct version (3)' );

# try loading the same file. Should fail because we can't have exactly
# the same file loaded twice (MD5 in filename should differ)
throws_ok { $file = File->load($assembly, '/home/testuser/ERS111111_123456789a123456789b123456789cdc_12345678-1234-1234-1234-1234567890ab.fa') }
  qr/(UNIQUE constraint failed|not unique)/,
  'loading same file again fails';

# variously broken filenames
throws_ok { $file = File->load() }
  qr/must supply both/,
  'loading fails with no arguments';

throws_ok { $file = File->load($assembly) }
  qr/must supply both/,
  'failed to load file with no path';

throws_ok { $file = File->load($assembly, 'ERS111111_123456789a123456789b123456789cdc_12345678-1234-1234-1234-1234567890ab.fa') }
  qr/must be an absolute path/,
  'failed to load file without an absolute path';

throws_ok { $file = File->load($assembly, '/home/testuser/ERS111111_123456789a123456789b123456789cdc_12345678-1234-1234-1234-1234567890ab') }
  qr/couldn't parse file path/,
  'failed to load file with no suffix';

throws_ok { $file = File->load($assembly, '/home/testuser/111111_123456789a123456789b123456789cdc_12345678-1234-1234-1234-1234567890ab.fa') }
  qr/can't find ERS/,
  'failed to load file with bad ERS number';

throws_ok { $file = File->load($assembly, '/home/testuser/ERS111111_23456789a123456789b123456789cdc_12345678-1234-1234-1234-1234567890ab.fa') }
  qr/can't find ERS/,
  'failed to load file with bad MD5';

throws_ok { $file = File->load($assembly, '/home/testuser/ERS111111_123456789a123456789b123456789cdc_12345678-1234-1234-1234-1234567890a.fa') }
  qr/can't find ERS/,
  'failed to load file with bad UUID';

# load a file for an assembly with no files
$assembly = MockAssembly->new(2);
lives_ok { $file = File->load($assembly, '/home/testuser/ERS111111_123456789a123456789b123456789cdd_12345678-1234-1234-1234-1234567890ab.fa') }
  'file loaded successfully';

is( File->count, 4, 'four files loaded now' );
is( $file->version, 1, 'new File has correct version (1)' );

# try loading with an assembly that doesn't exist
$assembly = MockAssembly->new(100);
throws_ok { $file = File->load($assembly, '/home/testuser/ERS333333_123456789a123456789b123456789cde_12345678-1234-1234-1234-1234567890ab.fa') }
  qr/no such sample/,
  'loading fails with non-existent assembly';

$DB::single = 1;

done_testing;

