use utf8;
package Bio::HICF::Schema::Result::Assembly;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Bio::HICF::Schema::Result::Assembly

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=item * L<DBIx::Class::PassphraseColumn>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "PassphraseColumn");

=head1 TABLE: C<assembly>

=cut

__PACKAGE__->table("assembly");

=head1 ACCESSORS

=head2 assembly_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 accession

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 20

=head2 type

  data_type: 'enum'
  extra: {list => ["ERS"]}
  is_nullable: 1

=head2 created_at

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0
  set_on_create: 1

=head2 updated_at

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1
  set_on_update: 1

=head2 deleted_at

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "assembly_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "accession",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 20 },
  "type",
  { data_type => "enum", extra => { list => ["ERS"] }, is_nullable => 1 },
  "created_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
    set_on_create => 1,
  },
  "updated_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
    set_on_update => 1,
  },
  "deleted_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</assembly_id>

=back

=cut

__PACKAGE__->set_primary_key("assembly_id");

=head1 RELATIONS

=head2 accession

Type: belongs_to

Related object: L<Bio::HICF::Schema::Result::Sample>

=cut

__PACKAGE__->belongs_to(
  "accession",
  "Bio::HICF::Schema::Result::Sample",
  { sample_accession => "accession" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 files

Type: has_many

Related object: L<Bio::HICF::Schema::Result::File>

=cut

__PACKAGE__->has_many(
  "files",
  "Bio::HICF::Schema::Result::File",
  { "foreign.assembly_id" => "self.assembly_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-03-20 15:44:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bb7WHqEpmYMrnMrb2JrTcw


use Carp qw(croak);

#-------------------------------------------------------------------------------

=head1 METHODS

=head2 get_files

Returns a L<DBIx::Class::ResultSet|ResultSet> containing all
L<Bio::HICF::Schema::Result::File|Files> for this assembly. Where an assembly
has multiple file versions, the resultset is ordered by decreasing version,
i.e. the most latest version is first in the list.

=cut

sub get_files {
  my $self = shift;

  return $self->search_related( 'files', {}, { order_by => { -desc => ['version'] } } );
}

#-------------------------------------------------------------------------------

=head2 get_file( ?$version )

Returns the given L<Bio::HICF::Schema::Result::File|File> for this assembly.
If C<$version> is given, the method returns that specific version, throwing an
exception if a file with that version doesn't exist. If C<$version> is not
given, we return the file with the latest version.

=cut

sub get_file {
  my ( $self, $version ) = @_;

  if ( defined $version ) {
    croak 'ERROR: version must be a positive integer'
      unless ( $version =~ m/^\d+$/ and $version > 0 );
  }

  my $files = $version
            ? $self->search_related( 'files', { version => $version }, {} )
            : $self->search_related( 'files', {}, { order_by => { -desc => ['version'] } } );

  croak 'ERROR: no files for this assembly' unless $files->count;

  return $files->first;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;
1;
