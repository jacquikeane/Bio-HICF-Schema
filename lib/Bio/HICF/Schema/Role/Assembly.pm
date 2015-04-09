
package Bio::HICF::Schema::Role::Assembly;

# ABSTRACT: role carrying methods for the Assembly table

use Moose::Role;

requires qw(
  assembly_id
  accession
  type
  created_at
  updated_at
  deleted_at
);

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

1;

