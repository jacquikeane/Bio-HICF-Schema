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

sub load_manifest {
  my ( $self, $manifest ) = @_;

  croak 'not a Bio::Metadata::Manifest'
    unless ref $manifest eq 'Bio::Metadata::Manifest';

  my $v = Bio::Metadata::Validator->new;

  croak 'the data in the manifest are not valid'
    unless $v->validate($manifest);

  my $field_names = $manifest->field_names;

  foreach my $row ( $manifest->all_rows ) {
    # add a row to the manifest table
    my $rs = $self->resultset('Manifest')
                  ->find_or_create( { manifest_id => $manifest->uuid,
                                      md5         => $manifest->md5 },
                                    { key => 'primary' } );

    # zip the field names and values together to form a hash...
    my %upload = mesh @$field_names, @$row;

    # ... add the manifest ID...
    $upload{manifest_id} = $manifest->uuid;

    # ... and pass that hash to the ResultSet to load
    $self->resultset('Sample')->load_row(\%upload);
  }
}

#-------------------------------------------------------------------------------

sub get_manifest {
  my ( $self, $manifest_id ) = @_;

  #...
  # return @samples;
}

#-------------------------------------------------------------------------------

sub get_sample {
  my ( $self, $sample_id ) = @_;

  # ...
  # return $sample;
}

#-------------------------------------------------------------------------------

sub get_samples {
  my $self = shift;

  my @samples;

  if ( $_[0] =~ m//i ) {
    # we were handed a manifest ID
    @samples = $self->_get_samples_from_manifest(shift);
  }
  else {
    my $sample_ids = ( ref $_[0] eq 'ARRAY' )
                   ? $_[0]
                   : \@_;
    # we were handed a list of sample IDs
    push @samples, $self->get_sample($_) for @$sample_ids;
  }

  return @samples;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;
