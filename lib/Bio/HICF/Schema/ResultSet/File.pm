use utf8;
package Bio::HICF::Schema::ResultSet::File;

use Moose;
use MooseX::NonMoose;
use MooseX::Params::Validate;
use Carp qw ( croak );
use Try::Tiny;
use File::Basename;

extends 'DBIx::Class::ResultSet';

sub BUILDARGS { $_[2] }
# see https://metacpan.org/pod/DBIx::Class::ResultSet#ResultSet-subclassing-with-Moose-and-similar-constructor-providers

#-------------------------------------------------------------------------------

=head1 METHODS

=head2 load

Loads the details of an assembly file. Takes two arguments:

=over 4

=item $assembly

reference to a L<Bio::HICF::Schema::ResultSet::Assembly> object for this file

=item $path

string giving the full path to the file

=over

Returns the created row.

=cut

sub load {
  my ( $self, $assembly, $path ) = @_;

  croak 'ERROR: must supply both assembly and path'
    unless ( defined $assembly and defined $path );

  croak 'ERROR: no assembly given' unless defined $assembly;

  croak 'ERROR: no path given' unless defined $path;
  # croak 'ERROR: no such file'  unless -e $path; # TODO do we need to check for that here?

  my ( $filename, $dirs, $suffix ) = fileparse( $path, qr/\.[^.]*/ );

  croak "ERROR: couldn't parse file path"
    unless ( defined $filename and $filename ne '' and
             defined $dirs     and $dirs     ne '' and
             defined $suffix   and $suffix   ne '' );

  croak 'ERROR: must be a FASTA file (suffix ".fa")' unless $suffix eq '.fa';
  croak 'ERROR: must be a full path' unless $dirs =~ m|^/|;

  croak "ERROR: can't find ERS number and MD5 in filename"
    unless $filename =~ m/^(ERS\d{6})_([a-f0-9]{32})$/i;

  my $accession = $1;
  my $md5       = $2;

  # check that the sample exists
  my $schema = $self->result_source->schema;
  my $sample = $schema->get_sample_by_accession($accession);

  croak "ERROR: no such sample (accession '$accession')" unless defined $sample;

  my $files = $self->search( { assembly_id => $assembly->assembly_id },
                             { order_by => { -desc => [ 'version' ] } } );

  my $version = ( defined $files and $files->count )
              ? ( $files->first->version + 1 )
              : 1;

  my $file_row;

  try {
    $file_row = $self->find_or_create(
      {
        assembly_id => $assembly->assembly_id,
        version     => $version,
        path        => $path,
        md5         => $md5
      },
      { key => 'file_version_UNIQUE' }
    );
  }
  catch {
    croak "ERROR: failed to load file: $_";
  };

  return $file_row;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;
