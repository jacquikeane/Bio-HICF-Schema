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

=head2 load_assembly

Given a path to an assembly file, this method stores the file location in the
L<Bio::HICF::Schema::Result::File|File> and
L<Bio::HICF::Schema::Result::Assembly|Assembly> tables.

=cut

sub load_assembly {
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

  croak "ERROR: can't find ERS number and MD5 in filename"
    unless $filename =~ m/^(ERS\d{6})_([a-f0-9]{32})$/i;

  my $accession = $1;

  # check that the sample exists
  my $schema = $self->result_source->schema;
  my $sample = $schema->resultset('Sample')
                      ->find( { sample_accession => $accession },
                              { key => 'sample_accession_UNIQUE' } );

  croak "ERROR: no such sample (accession '$accession')" unless defined $sample;

  my $assembly = $self->find_or_create( { accession => $accession, type => 'ERS' } );

  my $file_row = $schema->resultset('File')->load_file($path);

  # how many versions do we have so far ?
  my $files = $assembly->related_resultset('files');
  my $version = ( defined $files )
              ? ( $files->count + 1 )
              : 1;

  $assembly->version( $version );

  $DB::single = 1;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;
