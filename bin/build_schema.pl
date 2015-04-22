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

my $database = $ENV{HICF_DB_NAME};
my $db_host  = $ENV{HICF_DB_HOST};
my $db_port  = $ENV{HICF_DB_PORT};

my $username = $ENV{HICF_DB_USERNAME};
my $password = $ENV{HICF_DB_PASSWORD};

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

    # add custom column information for certain columns
    custom_column_info => sub {
      my ( $table, $column_name, $column_info ) = @_;

      # make the created_ad and updated_at update automatically when the
      # relevant operation is performed on the column
      return { set_on_create => 1 } if $column_name eq 'created_at';
      # return { set_on_update => 1 } if $column_name eq 'updated_at';

      # make the passphrase column treat passphrases as salted digests and
      # set the parameters for that
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
      User => 'Bio::HICF::Schema::Role::User',
    },
  },
  [
    "dbi:mysql:database=$database;host=$db_host;port=$db_port",
    $username,
    $password,
  ]
);

