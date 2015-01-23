use utf8;
package Bio::HICF::Schema::ResultSet::Sample;

use Moose;
use MooseX::NonMoose;
use List::MoreUtils qw( mesh );
use DateTime;
use Carp qw ( croak );

extends 'DBIx::Class::ResultSet';

sub BUILDARGS { $_[2] }
# see https://metacpan.org/pod/DBIx::Class::ResultSet#ResultSet-subclassing-with-Moose-and-similar-constructor-providers

has '_field_order' => (
  is => 'ro',
  default => sub { [ qw(
    raw_data_accession
    sample_accession
    sample_description
    collected_at
    ncbi_taxid
    scientific_name
    collected_by
    source
    collection_date
    location
    host_associated
    specific_host
    host_disease_status
    host_isolation_source
    isolation_source
    serovar
    other_classification
    strain
    isolate
    antimicrobial_resistance
  ) ] }
);

#-------------------------------------------------------------------------------

sub load_row {
  my ( $self, $upload ) = @_;

  croak 'not a valid row' unless ref $upload eq 'HASH';

  # parse out the antimicrobial resistance data and put them back into the row
  # hash in a format that means they'll get inserted correctly in the child
  # table
  my $amr = [];
  if ( my $amr_string = delete $upload->{antimicrobial_resistance} ) {
    while ( $amr_string =~ m/(([A-Za-z\d\- ]+);([SIR]);(\d+)(;(\w+))?),? */g) {
      push @$amr, {
        antimicrobial_name => $2,
        susceptibility     => $3,
        mic                => $4,
        diagnostic_centre  => $6
      }
    }
    $upload->{antimicrobial_resistances} = $amr;
  }

  my $rs = $self->find_or_create( $upload, { key => 'sample_uc' } );
}

#-------------------------------------------------------------------------------

sub get_sample {
  my ( $self, $sample_id ) = @_;

  my $sample = $self->find( $sample_id );

  foreach my $field ( @{ $self->_field_order } ) {
    
  }
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;
