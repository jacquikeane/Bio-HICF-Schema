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

use Carp qw( croak );
use Bio::Metadata::Validator;
use List::MoreUtils qw( mesh );

#-------------------------------------------------------------------------------

=head1 METHODS

=head2 load_manifest($manifest)

Loads the sample data in a L<Bio::Metadata::Manifest>.

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

  foreach my $row ( $manifest->all_rows ) {

    # zip the field names and values together to form a hash...
    my %upload = mesh @$field_names, @$row;

    # ... add the manifest ID...
    $upload{manifest_id} = $manifest->uuid;

    # ... and pass that hash to the ResultSet to load
    $self->resultset('Sample')->load_row(\%upload);
  }
}

#-------------------------------------------------------------------------------

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

sub get_manifest {
  my ( $self, $manifest_id ) = @_;

  # create a B::M::Config object from the config string that we have stored for
  # this manifest
  my $config_rs = $self->resultset('Manifest')
                       ->search( { manifest_id => $manifest_id },
                                 { prefetch => [ 'config' ] } )
                       ->single;

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

__PACKAGE__->meta->make_immutable;

1;
