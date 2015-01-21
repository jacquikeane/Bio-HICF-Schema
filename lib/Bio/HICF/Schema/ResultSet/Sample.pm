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

sub load_row {
  my ( $self, $row ) = @_;

  croak 'not a valid row' unless ref $row eq 'HASH';

  # parse out the antimicrobial resistance data and put them back into the row
  # hash in a format that means they'll get inserted correctly in the child
  # table
  my $amr = [];
  if ( my $amr_string = delete $row->{antimicrobial_resistance} ) {
    while ( $amr_string =~ m/(([A-Za-z\d\- ]+);([SIR]);(\d+)(;(\w+))?),? */g) {
      push @$amr, {
        antimicrobial_name => $2,
        susceptibility     => $3,
        mic                => $4,
        diagnostic_centre  => $6
      }
    }
    $row->{antimicrobial_resistances} = $amr;
  }

  $self->update_or_create( $row );
  # $self->update_or_create( $row, { key => 'primary' } );
}

__PACKAGE__->meta->make_immutable;

1;
