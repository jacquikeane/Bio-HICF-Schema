use utf8;
package Bio::HICF::Schema::ResultSet::Assembly;

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

Given a path to an assembly file, this method stores the file location in the
L<Bio::HICF::Schema::Result::File|File> and
L<Bio::HICF::Schema::Result::Assembly|Assembly> tables.

The file path must conform to a particular format:

            /path/ERS123456_123456789012345678901234567890ab_46E60168-E51B-11E4-9601-77777D11CFBA.fa
      path -^^^^^^
 accession -------^^^^^^^^^
       MD5 -----------------^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
      UUID --------------------------------------------------^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    suffix ---------------------------------------------------------------------------------------^^

The path must be absolute, i.e. it must have a leading slash (C</>).

The sample accession must correspond to a sample in the database. If there is
no loaded sample with the specified accession, an exception is thrown.

Before loading the MD5 checksum for the file is calculated it must agree with
the checksum part of the filename. An exception is thrown if the two checksums
do not agree.

Files must have a UUID, which is used to place them in the storage directory
structure.

Assembly files must (currently) be in FASTA format, having the suffix C<fa>.
We don't check the B<actual> format of the file, but an exception is thrown if
the suffix is no C<fa>.

=cut

sub load {
  my ( $self, $path ) = @_;

  croak 'ERROR: no path given' unless defined $path;
  # croak 'ERROR: no such file'  unless -e $path; # TODO do we need to check for that here?

  my ( $filename, $dirs, $suffix ) = fileparse( $path, qr/\.[^.]*/ );

  croak "ERROR: couldn't parse file path"
    unless ( defined $filename and $filename ne '' and
             defined $dirs     and $dirs     ne '' and
             defined $suffix   and $suffix   ne '' );

  croak 'ERROR: must be a FASTA file (suffix ".fa")' unless $suffix eq '.fa';
  croak 'ERROR: must be a full path' unless $dirs =~ m|^/|;

  croak "ERROR: can't find ERS number, MD5 and UUID in filename"
    unless $filename =~ m/^(ERS\d{6})_([a-f0-9]{32})_([0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12})$/i;
    # note that there's no suffix in the regex, because that's already stripped
    # off by fileparse
  # TODO need to expand this to handle more types

  my $accession = $1;

  # check that the sample exists
  my $schema = $self->result_source->schema;
  my $sample = $schema->resultset('Sample')
                      ->search( { sample_accession => $accession },
                                { order_by => { -desc => [ qw( sample_id ) ] } } );

  croak "ERROR: no such sample (accession '$accession')"
    unless ( defined $sample and $sample->count > 0 );

  # get a row for the assembly...
  my $assembly_row = $self->find_or_create( { sample_accession => $accession, type => 'ERS' } );
  # TODO need to expand the list of types

  # ... and for the file
  my $file_row = $schema->resultset('File')->load($assembly_row, $path);

  return $assembly_row;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;
