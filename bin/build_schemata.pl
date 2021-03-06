#!/usr/bin/env perl
#
# build_schemata.pl
# jt6 20150527 WTSI
#
# dumps the two HICF schemata as DBIC models

# ABSTRACT: dump the HICF database schemata as DBIC schemata
# PODNAME: build_schemata.pl

use strict;
use warnings;

use DBIx::Class::Schema::Loader qw( make_schema_at );

#-------------------------------------------------------------------------------
# configuration

my $db_host  = $ENV{HICF_DB_HOST};
my $db_port  = $ENV{HICF_DB_PORT};

my $username = $ENV{HICF_DB_USERNAME};
my $password = $ENV{HICF_DB_PASSWORD};

my $dump_path = './lib';

die 'ERROR: must set $ENV{HICF_DB_DATA_DATABASE} and $ENV{HICF_DB_USER_DATABASE'
  unless ( defined $ENV{HICF_DB_DATA_DATABASE} and
           defined $ENV{HICF_DB_USER_DATABASE} );

#-------------------------------------------------------------------------------

# first, the schema containing the HICF data:
#
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

my $database = $ENV{HICF_DB_DATA_DATABASE};

make_schema_at(
  "Bio::HICF::Schema",
  {
    components         => [ 'InflateColumn::DateTime', 'TimeStamp', 'PassphraseColumn' ],
    dump_directory     => $dump_path,
    use_moose          => 1,

    # add custom column information for certain columns
    custom_column_info => sub {
      my ( $table, $column_name, $column_info ) = @_;

      # make the created_at and updated_at update automatically when the
      # relevant operation is performed on the column
      return { set_on_create => 1 } if $column_name eq 'created_at';
    },

    # use "col_accessor_map" to set the name for the column accessors for those
    # columns that allow "unknown", allowing us to overload the accessors and
    # handle unknowns appropriately as the data go in and out of the DB
    col_accessor_map => {
      collection_date       => '_collection_date',
      location              => '_location',
      host_associated       => '_host_associated',
      specific_host         => '_specific_host',
      host_disease_status   => '_host_disease_status',
      host_isolation_source => '_host_isolation_source',
      patient_location      => '_patient_location',
      isolation_source      => '_isolation_source',
    },

    # this allows us to move the functionality for the ResultSets out into
    # roles. The loader will have the specified ResultSet add a "with <role>"
    # for each RS in the map
    result_roles_map => {
      Antimicrobial => 'Bio::HICF::Schema::Role::Undeletable',
      AntimicrobialResistance => [
        'Bio::HICF::Schema::Role::AntimicrobialResistance',
        'Bio::HICF::Schema::Role::Undeletable',
      ],
      Assembly => [
        'Bio::HICF::Schema::Role::Assembly',
        'Bio::HICF::Schema::Role::Undeletable',
      ],
      File => 'Bio::HICF::Schema::Role::Undeletable',
      Manifest => [
        'Bio::HICF::Schema::Role::Manifest',
        'Bio::HICF::Schema::Role::Undeletable',
      ],
      Sample   => [
        'Bio::HICF::Schema::Role::Sample',
        'Bio::HICF::Schema::Role::Undeletable',
      ],
    },
  },
  [
    "dbi:mysql:database=$database;host=$db_host;port=$db_port",
    $username,
    $password,
  ]
);

# next, the schema containing the user data and the MIDAS session data.
# This one will be accessed using a R/W account, hence we want it
# separated off from the live data

$database = $ENV{HICF_DB_USER_DATABASE};

make_schema_at(
  "Bio::HICF::User",
  {
    components         => [ 'InflateColumn::DateTime', 'TimeStamp', 'PassphraseColumn' ],
    dump_directory     => $dump_path,
    use_moose          => 1,

    # add custom column information for certain columns
    custom_column_info => sub {
      my ( $table, $column_name, $column_info ) = @_;

      # make the created_at and updated_at update automatically when the
      # relevant operation is performed on the column
      return { set_on_create => 1 } if $column_name eq 'created_at';

      # make the passphrase column treat passphrases as salted digests and
      # set the parameters for that
      if ( $column_name eq 'passphrase' or
           $column_name eq 'api_key'       ) {
        my $method = $column_name eq 'passphrase'
                   ? 'check_password'
                   : 'check_api_key';
        return {
          passphrase       => 'rfc2307',
          passphrase_class => 'SaltedDigest',
          passphrase_args  => {
            algorithm   => 'SHA-1',
            salt_random => 20,
          },
          passphrase_check_method => $method,
        };
      }
    },

    # this allows us to move the functionality for the ResultSets out into
    # roles. The loader will have the specified ResultSet add a "with <role>"
    # for each RS in the map
    result_roles_map => {
      User => 'Bio::HICF::User::Role::User',
    },
  },
  [
    "dbi:mysql:database=$database;host=$db_host;port=$db_port",
    $username,
    $password,
  ]
);
