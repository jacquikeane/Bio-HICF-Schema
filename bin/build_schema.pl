#!/usr/bin/env perl
#
# build_schema.pl
# jt6 20141125 WTSI
#
# dumps the schema as a DBIC model

# ABSTRACT: dump the HICF database schema as a DBIC schema
# PODNAME: build_schema.pl

use strict;
use warnings;

use DBIx::Class::Schema::Loader qw( make_schema_at );

#-------------------------------------------------------------------------------
# configuration

my $database = 'pathogen_hicf_test';
my $db_host  = 'mcs11.internal.sanger.ac.uk';
my $db_port  = 3346;

my $username = 'pathpipe_ro';
my $password = '';

my $dump_path = './lib';

#-------------------------------------------------------------------------------

# we're adding three components to the ResultSets:
#   InflateColumn::DateTime
#     allows DBIC to inflate DATETIME columns to DateTime objects automatically
#   TimeStamp
#     allows DBIC automatically to update timestamp columns on update or create.
#     We have to explicitly add flags to the column definitions when making the
#     schema classes, which is done using the "custom_column_info" hook. See
#     the docs for DBIx::Class::TimeStamp for details.
#   PassphraseColumn
#     allows DBIC to store and access passphrases as salted digests

make_schema_at(
  "Bio::HICF::Schema",
  {
    components         => [ 'InflateColumn::DateTime', 'TimeStamp', 'PassphraseColumn' ],
    dump_directory     => $dump_path,
    use_moose          => 1,
    custom_column_info => sub {
      my ( $table, $column_name, $column_info ) = @_;
      return { set_on_create => 1 } if $column_name eq 'created_at';
      return { set_on_update => 1 } if $column_name eq 'updated_at';
      if ( $column_name eq 'passphrase' ) {
        return {
          passphrase       => 'rfc2307',
          passphrase_class => 'SaltedDigest',
          passphrase_args  => {
            algorithm   => 'SHA-1',
            salt_random => 20,
          },
          passphrase_check_method => 'check_password',
        };
      }
    },
  },
  [
    "dbi:mysql:database=$database;host=$db_host;port=$db_port",
    $username,
    $password,
  ]
);

