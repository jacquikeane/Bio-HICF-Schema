
package Bio::HICF::Schema::Role::Assembly;

# ABSTRACT: role carrying methods for the Assembly table

use Moose::Role;

requires qw(
  assembly_id
  sample_accession
  type
  created_at
  deleted_at
);

use Carp qw(croak);

#-------------------------------------------------------------------------------

=head1 METHODS

=head2 get_file(?$version,?$include_deleted)

Returns the given L<Bio::HICF::Schema::Result::File|File> for this assembly.
If C<$version> is given, the method returns that specific version. If
C<$version> is not given, we return the file with the latest version. Returns
C<undef> if there is no file to return.

If C<$include_deleted> is omitted or false, any returned row will be "live",
i.e. it will not have been flagged as deleted. If C<$include_deleted> is true,
the returned files may have been flagged as deleted.

=cut

sub get_file {
  my ( $self, $version, $include_deleted ) = @_;

  if ( defined $version ) {
    croak 'ERROR: version must be a positive integer'
      unless ( $version =~ m/^\d+$/ and $version > 0 );
  }

  # default to returning only files that haven't been deleted, ordered by
  # version number
  my $query = $include_deleted
            ? { }
            : { deleted_at => { '=', undef } };
  my $attrs = { order_by => { '-desc', ['version'] } };

  # should we get a specific version ?
  $query->{version} = $version if $version;

  # run the query
  my $files = $self->search_related( 'files', $query, $attrs );

  return undef unless $files;

  return $files->first;
}

#-------------------------------------------------------------------------------

=head2 get_files(?$include_deleted)

Returns a L<DBIx::Class::ResultSet|ResultSet> containing all of the
L<Bio::HICF::Schema::Result::File|Files> for this assembly.

If C<$include_deleted> is omitted or is false, we return all "live" files for
this assembly, that is, file which have not been deleted. If
C<$include_deleted> is true, we return all files for the assembly, both live
and deleted.

Where an assembly has multiple file versions, all versions are returned and the
resultset is ordered by decreasing version number, i.e. the most recent version
is first in the list.

=cut

sub get_files {
  my ( $self, $include_deleted ) = @_;

  my $query = $include_deleted
            ? { }
            : { 'deleted_at' => { '=',  undef } };

  return $self->search_related(
    'files',
    $query,
    { order_by => { -desc => ['version'] } }
  );
}

#-------------------------------------------------------------------------------
#- method modifiers ------------------------------------------------------------
#-------------------------------------------------------------------------------

# when an Assembly is marked as deleted, also mark related File rows as deleted

after 'delete' => sub {
  my $self = shift;
  $_->mark_as_deleted for $self->search_related('files')->all;
};

#-------------------------------------------------------------------------------

1;

