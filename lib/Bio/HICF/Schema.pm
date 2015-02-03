use utf8;
package Bio::HICF::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-01-13 15:26:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/Tydb6euSFy7u3YcKYKMrA

# ABSTRACT: DBIC schema for the HICF repository

=head1 SYNOPSIS

 # read in a manifest
 my $c = Bio::Metadata::Config->new( config_file => 'hicf.conf' );
 my $r = Bio::Metadata::Reader->new( config => $c );
 my $m = $r->read_csv( 'hicf.csv' );

 # load it into the database
 my $schema = Bio::HICF::Schema->connect( $dsn, $username, $password );
 my @sample_ids = $schema->load_manifest($m);

=cut

use Carp qw( croak );
use Bio::Metadata::Validator;
use List::MoreUtils qw( mesh );
use MooseX::Params::Validate;
use TryCatch;

#-------------------------------------------------------------------------------

=head1 METHODS

=head2 load_manifest($manifest)

Loads the sample data in a L<Bio::Metadata::Manifest>. Returns a list of the
sample IDs for the newly inserted rows.

=cut

sub load_manifest {
  my ( $self, $manifest ) = @_;

  croak 'not a Bio::Metadata::Manifest'
    unless ref $manifest eq 'Bio::Metadata::Manifest';

  my $v = Bio::Metadata::Validator->new;

  croak 'the data in the manifest are not valid'
    unless $v->validate($manifest);

  # add a row to the manifest table
  my $rs = $self->resultset('Manifest')
                ->find_or_create(
                  {
                    manifest_id => $manifest->uuid,
                    md5         => $manifest->md5,
                    config      => { config => $manifest->config->config_string }
                  },
                  { key => 'primary' }
                );

  # load the sample rows
  my $field_names = $manifest->field_names;

  # TODO we should perhaps put this in a transaction, so that if a load_row
  # TODO fails, we can roll back the inserts for the whole manifest

  my @row_ids;
  foreach my $row ( $manifest->all_rows ) {

    # zip the field names and values together to form a hash...
    my %upload = mesh @$field_names, @$row;

    # ... add the manifest ID...
    $upload{manifest_id} = $manifest->uuid;

    # ... and pass that hash to the ResultSet to load
    push @row_ids, $self->resultset('Sample')->load_row(\%upload);
  }

  return @row_ids;
}

#-------------------------------------------------------------------------------

=head2 get_sample($sample_id)

Returns a reference to an array containing the field values for the specified
sample.

=cut

sub get_sample {
  my ( $self, $sample_id ) = @_;

  my $sample = $self->resultset('Sample')
                    ->find($sample_id);
  croak "ERROR: no sample with that ID ($sample_id)"
    unless defined $sample;

  my $values = $sample->get_field_values;
  croak "ERROR: couldn't get values for sample $sample_id"
    unless ( defined $values and scalar @$values );

  return $values;
}

#-------------------------------------------------------------------------------

=head2 get_samples(@args)

Returns a reference to an array containing the field values for the specified
samples, one sample per row. If the first element of C<@args> looks like a UUID,
it's assumed to be a manifest ID and the method returns the field data for all
samples in that manifest. Otherwise C<@args> is assumed to be a list of sample
IDs and the field data for each is return.

=cut

sub get_samples {
  my ( $self, @args ) = @_;

  my $samples;

  if ( $args[0] =~ m/^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$/i ) {
    # we were handed a manifest ID
    my $rs = $self->resultset('Sample')
                  ->search( { manifest_id => $args[0] },
                            { prefetch => 'antimicrobial_resistances' } );
    push @$samples, $_->get_field_values for ( $rs->all );
  }
  else {
    my $sample_ids = ( ref $args[0] eq 'ARRAY' )
                   ? $args[0]
                   : \@args;
    # we were handed a list of sample IDs
    push @$samples, $self->get_sample($_) for @$sample_ids;
  }

  return $samples;
}

#-------------------------------------------------------------------------------

=head2 get_manifest($manifest_id)

Returns a L<Bio::Metadata::Manifest> object for the specified manifest.

=cut

sub get_manifest {
  my ( $self, $manifest_id ) = @_;

  # create a B::M::Config object from the config string that we have stored for
  # this manifest
  my $config_rs = $self->resultset('Manifest')
                       ->search( { manifest_id => $manifest_id },
                                 { prefetch => [ 'config' ] } )
                       ->single;

  return unless $config_rs;

  my %config_args = ( config_string => $config_rs->config->config );
  if ( defined $config_rs->config->name ) {
    $config_args{config_name} = $config_rs->config->name;
  }

  my $c = Bio::Metadata::Config->new(%config_args);

  # get the values for the samples in the manifest and add them to a new
  # B::M::Manifest
  my $values = $self->get_samples($manifest_id);
  my $m = Bio::Metadata::Manifest->new( config => $c, rows => $values );

  return $m;
}

#-------------------------------------------------------------------------------

=head2 add_antimicrobial($name)

Adds the specified antimicrobial to the database. Throws an exception if the
named compound is already found in the database, or if the supplied name is
invalid, e.g. contains non-word characters.

=cut

sub add_antimicrobial {
  my ( $self, $name ) = @_;

  return unless defined $name;

  croak 'ERROR: invalid antimicrobial name'
    unless $name =~ m/^[A-Z0-9\-\(\)\s]+$/i;

  my $am = $self->resultset('Antimicrobial')
                ->find_or_new( { name => $name },
                               { key => 'primary' } );

  croak 'ERROR: antimicrobial already exists' if $am->in_storage;

  $am->insert;
}

#-------------------------------------------------------------------------------

=head2 add_antimicrobial_resistance($args)

Adds the specified antimicrobial resistance rest result to the database. Requires
a single argument, a hash containing the parameters specifying the resistance
test. The hash must contain the following five keys:

=over

=item C<sample_id> - the ID of an existing sample

=item C<name> - the name of an existing antimicrobial

=item C<susceptibility> - a susceptibility term; must be one of "S", "I" or "R"

=item C<mic> - minimum inhibitor concentration, in microgrammes per millilitre; must be a valid integer
=item C<diagnostic_centre> - name of the centre that carried out the susceptibility testing; optional

=back

Throws an exception if any of the parameters is invalid, or if the resistance
test result is already present in the database.

=cut

sub add_antimicrobial_resistance {
  my ( $self, %params ) = validated_hash(
    \@_,
    sample_id         => { isa => 'Int' },
    name              => { isa => 'Bio::Metadata::Types::AntimicrobialName' },
    susceptibility    => { isa => 'Bio::Metadata::Types::SIRTerm' },
    mic               => { isa => 'Int' },
    diagnostic_centre => { isa => 'Str' },
  );

  my $amr = $self->resultset('AntimicrobialResistance')->find_or_new(
    {
      sample_id          => $params{sample_id},
      antimicrobial_name => $params{name},
      susceptibility     => $params{susceptibility},
      mic                => $params{mic},
      diagnostic_centre  => $params{diagnostic_centre}
    },
    { key => 'primary' }
  );

  croak 'ERROR: antimicrobial resistance result already exists' if $amr->in_storage;

  try {
    $amr->insert;
  }
  catch ( DBIx::Class::Exception $e where { m/FOREIGN KEY constraint failed/ } ) {
    croak "ERROR: both the antimicrobial and the sample must exist";
  }
}

#-------------------------------------------------------------------------------

=head1 SEE ALSO

L<Bio::Metadata::Validator>

=head1 CONTACT

path-help@sanger.ac.uk

=cut

__PACKAGE__->meta->make_immutable;

1;
