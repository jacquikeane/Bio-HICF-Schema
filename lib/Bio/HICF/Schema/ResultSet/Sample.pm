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

#-------------------------------------------------------------------------------

sub load_row {
  my ( $self, $upload ) = @_;

  croak 'not a valid row' unless ref $upload eq 'HASH';

  # parse out the antimicrobial resistance data and put them back into the row
  # hash in a format that means they'll get inserted correctly in the child
  # table
  if ( my $amr_string = delete $upload->{antimicrobial_resistance} ) {
    my $amr = [];
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

  # TODO currently we're not taking any notice if a row already exists in the
  # TODO database. Need to decide if that's the behaviour we want, or if this
  # TODO method should throw an exception if the sample already exists
  my $rs = $self->find_or_create( $upload, { key => 'sample_uc' } );

  return $rs->sample_id;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;
