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

use Bio::Metadata::Checklist;
use Bio::Metadata::Reader;
use Bio::Metadata::Manifest;
use Bio::HICF::Schema;

#---------------------------------------

=head1 ATTRIBUTES

=attr checklist

L<Bio::Metadata::Checklist> to be used for validating the loaded files.

=cut

has checklist => (
  is      => 'ro',
  isa     => 'Bio::Metadata::Checklist',
  default => sub {
    die 'ERROR: must specify a checklist config (set $HICF_CHECKLIST_CONFIG)'
      unless defined $ENV{HICF_CHECKLIST_CONFIG};
    die "ERROR: can't find config file specified by environment variable ($ENV{HICF_CHECKLIST_CONFIG})"
      unless -f $ENV{HICF_CHECKLIST_CONFIG};
    return Bio::Metadata::Checklist->new( config_file => $ENV{HICF_CHECKLIST_CONFIG} );
  },
);

#---------------------------------------

=attr reader

L<Bio::Metadata::Reader> that will be used for reading and parsing sample files.

=cut

has reader => (
  is      => 'ro',
  isa     => 'Bio::Metadata::Reader',
  lazy    => 1,
  default => sub {
    my $self = shift;
    return Bio::Metadata::Reader->new( checklist => $self->checklist );
  },
);

#---------------------------------------

=attr config

A hashref containing the script configuration parameters. Loaded from the file
specified by the environment variable C<HICF_SCRIPT_CONFIG>. An exception is
thrown if the environment variable is not set or if the file pointed to by that
variable can't be read by L<Config::General>.

=cut

has config => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub {
    die 'ERROR: must specify a script configuration file (set $HICF_SCRIPT_CONFIG)'
      unless defined $ENV{HICF_SCRIPT_CONFIG};
    die "ERROR: can't find config file specified by environment variable ($ENV{HICF_SCRIPT_CONFIG})"
      unless -f $ENV{HICF_SCRIPT_CONFIG};
    my $cg;
    try {
      $cg = Config::General->new( $ENV{HICF_SCRIPT_CONFIG} );
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

=attr config

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
    my $connect_info = $self->config->{database}->{connect_info};
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
    count_files => 'count',
    has_files   => 'count',
    ignore_file => 'delete',
  },
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
}

#-------------------------------------------------------------------------------

=head2 load_files

Description

=cut

sub load_files {
  my ( $self, $args ) = @_;

  # body
}

#-------------------------------------------------------------------------------
#- private methods -------------------------------------------------------------
#-------------------------------------------------------------------------------

# validates the current set of filenames, checking that the specified file
# exists, the filename has the correct format, the MD5 checksum matches. This
# is used as a trigger for the C<files> attribute.

sub _validate_files {
  my ( $self, $files ) = @_;

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

    # the filename doesn't have the expected format...
    # TODO this needs to fixed, like the same test in
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

__PACKAGE__->meta->make_immutable;

1;

