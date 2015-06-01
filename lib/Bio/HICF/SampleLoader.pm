use utf8;
package Bio::HICF::SampleLoader;

# ABSTRACT: find, validate and load sample metadata files in a dropbox directory
# jt6 20150417 WTSI

use Moose;
use namespace::autoclean;

use Try::Tiny;
use Config::General;
use Digest::MD5;
use File::Copy::Recursive qw(rmove);
use Data::UUID;
use File::Path qw(make_path);
use File::Basename;

use Bio::HICF::Schema;

#---------------------------------------

=head1 ATTRIBUTES

=attr config

A hashref containing the script configuration parameters. Loaded from the file
specified by the environment variable C<HICF_SCRIPT_CONFIG>. An exception is
thrown if the environment variable is not set or if the file pointed to by that
variable can't be read by L<Config::General>.

We enable variable interpolation in C<Config::General>, so you can use
environment variables to configure the location from outside the config file,
if required. See the test files for an example.

=cut

has config => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub {
    my $self = shift;

    die 'ERROR: must specify a script configuration file (set $HICF_SCRIPT_CONFIG)'
      unless defined $ENV{HICF_SCRIPT_CONFIG};
    die "ERROR: can't find config file specified by environment variable ($ENV{HICF_SCRIPT_CONFIG})"
      unless -f $ENV{HICF_SCRIPT_CONFIG};

    my $cg;
    try {
      $cg = Config::General->new(
        -ConfigFile      => $ENV{HICF_SCRIPT_CONFIG},
        -InterPolateEnv  => 1,
        -InterPolateVars => 1,
      );
    }
    catch {
      die "ERROR: there was a problem reading the script configuration: $_";
    };
    my %config = $cg->getall;

    # Config::General seems happy to read any old cruft, so we need to check
    # the resulting hash and make sure its contents looks right. This is a bit
    # crude, but it might catch some problems.
    die 'ERROR: the loaded script config is not valid'
      unless ( exists $config{storage} and
               exists $config{database} );
    return \%config;
  },
);

#---------------------------------------

=attr dirs

A hashref giving names of the various directories required by the script. The
values are taken from the configuration file. The required keys are:

=over 4

=item dropbox

the directory to search for new manifest CSV files

=item archive

the directory where loaded files will be moved

=item failed

the directory where files will be moved if they are invalid (e.g. have the wrong
filename format) or fail to load

=back

=cut

has 'dirs' => (
  is      => 'ro',
  isa     => 'HashRef[Str]',
  lazy    => 1,
  default => sub {
    my $self = shift;
    my %dirs = (
      dropbox => $self->{config}->{storage}->{dropbox},
      archive => $self->{config}->{storage}->{archive},
      failed  => $self->{config}->{storage}->{failed},
    );
    return \%dirs;
  },
);

#---------------------------------------

=attr schema

Database connection object (L<Bio::HICF::Schema>).

=cut

has schema => (
  is      => 'ro',
  isa     => 'Bio::HICF::Schema',
  lazy    => 1,
  default => sub {
    my $self         = shift;
    my $connect_info = $self->config->{database}->{hicf}->{connect_info};
    return Bio::HICF::Schema->connect(@$connect_info);
  },
);

#---------------------------------------

=attr files

The list of all filenames to be loaded.

=cut

has files => (
  traits  => ['Array'],
  is      => 'rw',
  isa     => 'ArrayRef[Str]',
  default => sub { [] },
  trigger => \&_validate_files,
  handles => {
    all_files   => 'elements',
    clear_files => 'clear',
    count_files => 'count',
    has_files   => 'count',
    ignore_file => 'delete',
  },
);

#---------------------------------------

=attr data_uuid

Instance of L<Data::UUID>.

=cut

has 'data_uuid' => (
  is      => 'ro',
  default => sub { Data::UUID->new },
);

#-------------------------------------------------------------------------------
#- private attributes ----------------------------------------------------------
#-------------------------------------------------------------------------------

has '_found_files' => (
  is      => 'rw',
  isa     => 'Bool',
  default => 0,
);

#-------------------------------------------------------------------------------
#- construction ----------------------------------------------------------------
#-------------------------------------------------------------------------------

# validate the state of the object after construction

sub BUILD {
  my $self = shift;

  # check that the directories are all found
  while ( my ( $dir, $path ) = each %{ $self->dirs } ) {
    die "ERROR: path for required directory '$dir' is missing ($path): $!"
      unless -d $path;
  }
}

#-------------------------------------------------------------------------------
#- methods ---------------------------------------------------------------------
#-------------------------------------------------------------------------------

=head1 METHODS

=head2 all_files

Returns a list of all filenames.

=head2 clear_files

Empties the entire list of files.

=head2 count_files

Returns the number of files currently stored.

=head2 has_files

Returns true if there are files loaded.

=head2 ignore_file($i)

Removes the file at the specified index.

=cut

#-------------------------------------------------------------------------------

=head2 find_files

Looks for files in the dropbox directory and adds them to the C<files> list.
This method doesn't do anything with the files, it just finds them.

B<Note> that the filenames do not have the dropbox directory path prepended.
They are simply the local filename for the files within that directory. You can
find that directory as C<$loader->dirs->{dropbox}>.

=cut

sub find_files {
  my $self = shift;

  my $dropbox_dir = $self->dirs->{dropbox};

  opendir my $dh, $dropbox_dir
    or die "ERROR: can't read configured dropbox directory ($dropbox_dir): $!";
  my @dropped_files = grep { ! m/^\.+/ } readdir $dh;
  closedir $dh;

  $self->files( [ @dropped_files ] );
  $self->_found_files(1);
}

#-------------------------------------------------------------------------------

=head2 load_files

Loads the files in the dropbox into the database (actually, it's not the files
themselves that are loaded but their B<names>). You need to have run
L<find_files> first, or you'll get an error message to that effect.

If you prefer to provide a list of files yourself, set them first using
L<files>; B<note> that the path to the dropbox directory will be prepended
before the files are loaded. This mode of operation is untested.

=cut

sub load_files {
  my ( $self, $args ) = @_;

  warn "WARNING: no files to load; call 'find_files' before trying to load"
    unless $self->_found_files;

  foreach my $file ( $self->all_files ) {
    my $dropped_file = $self->dirs->{dropbox} . '/' . $file;

    my $archived_filename = $self->_get_archive_path( $file );

    my $txn = sub {
      # we "load" the file using it's eventual location in archive directory,
      # because really all the DB cares about is the format of the filename. If
      # that loading fails, we want to leave the actual file in the dropbox, so
      # that it will be picked up when the script next runs
      $self->schema->load_assembly($archived_filename);

      # once we're sure the filename is recorded in the DB, THEN we'll move
      # the actual file
      rmove( $dropped_file, $archived_filename )
        or die "ERROR: couldn't move loaded file from '$dropped_file' to '$archived_filename': $!";
    };

    try {
      $self->schema->txn_do( $txn );
    } catch {
      if ( m/Rollback failed/ ) {
        die "ERROR: loading assembly file '$dropped_file' failed but roll back also failed ($_)";
      }
      else {
        die "ERROR: loading assembly file '$dropped_file' failed and the changes were rolled back ($_)";
      }
    };

  }

}

#-------------------------------------------------------------------------------
#- private methods -------------------------------------------------------------
#-------------------------------------------------------------------------------

# this method calculates the path to an archived assembly file. In order to
# ensure a more or less even distribution of files across a directory tree, we
# append a UUID to the filename and use the first two and four characters to
# give us two levels of a directory hierarchy.

sub _get_archive_path {
  my ( $self, $file ) = @_;

  my $uuid = $self->data_uuid->create_str;
  my $level1 = substr( $uuid, 0, 2 );
  my $level2 = substr( $uuid, 2, 2 );
  my $archive_dir = $self->dirs->{archive} . "/$level1/$level2";

  unless ( -d $archive_dir ) {
    make_path $archive_dir
      or die "ERROR: couldn't create archive directory ($archive_dir): $!";
  }

  # split up the filename so that we can insert the UUID in there
  my ( $filename, $dirs, $suffix ) = fileparse( $file, qr/\.[^.]*/ );

  return "${archive_dir}/${filename}_${uuid}${suffix}";
}

#-------------------------------------------------------------------------------

# validates the current set of filenames, checking that the specified file
# exists, the filename has the correct format, the MD5 checksum matches. This
# is used as a trigger for the C<files> attribute.

sub _validate_files {
  my ( $self, $files ) = @_;

  return unless scalar @$files;

  my $dropbox_dir = $self->dirs->{dropbox};
  my $failed_dir  = $self->dirs->{failed};

  FILE: for ( my $i = 0; $i < scalar @$files; $i++ ) {
    my $file = $files->[$i];
    my $dropped_file = $dropbox_dir . '/' . $file;

    # reject the file if...

    # it's not really a file...
    unless ( -f $dropped_file ) {
      $self->_warn_and_move( "WARNING: '$dropped_file' is not a file", $files, $i );
      next FILE;
    }

    # it's empty...
    unless ( -s $dropped_file ) {
      $self->_warn_and_move( "WARNING: '$dropped_file' is empty", $files, $i );
      next FILE;
    }

    # the source filename doesn't have the expected format...
    # TODO this needs to be fixed, like the same test in
    # TODO Bio::HICF::Schema::ResultSet::File, if we have to accept files from
    # TODO different sources, such as NCBI
    unless ( $file =~ m/^(ERS\d{6})_([a-f0-9]{32}).fa$/i ) {
      $self->_warn_and_move( "WARNING: filename '$file' does not have the correct format", $files, $i );
      next FILE;
    }

    my $sample_accession = $1;
    my $md5              = $2;

    # calculate the MD5 checksum for the uploaded file and make sure it matches
    # the one given in the filename
    my $ctx = Digest::MD5->new;

    open ( my $fh, '<', $dropped_file )
      or die "ERROR: failed to open '$dropped_file' for reading: $!";
    $ctx->addfile($fh);
    close $fh;

    my $calculated_md5 = $ctx->hexdigest;

    unless ( $calculated_md5 eq $md5 ) {
      $self->_warn_and_move( "WARNING: calculated checksum for '$dropped_file' ($calculated_md5) does not match that in filename ($md5)",
        $files, $i );
      next FILE;
    }
  }
}

#-------------------------------------------------------------------------------

# convenience method to print a warning message and move the file with index
# $i from the dropbox to the failed folder.

sub _warn_and_move {
  my ( $self, $msg, $files, $i  ) = @_;
  my $from = $self->dirs->{dropbox} . '/' . $files->[$i];
  my $to   = $self->dirs->{failed}  . '/' . $files->[$i];
  warn $msg;
  rmove( $from, $to )
    or die "ERROR: couldn't move '$from' to '$to': $!";
  delete $files->[$i];
}

#-------------------------------------------------------------------------------

=head1 SEE ALSO

L<Bio::Metadata::Validator>

=head1 CONTACT

path-help@sanger.ac.uk

=cut

__PACKAGE__->meta->make_immutable;

1;

