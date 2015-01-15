use utf8;
package Bio::HICF::Schema::ResultSet::Sample;

use Moose;
use MooseX::NonMoose;
use List::MoreUtils qw( mesh );
use DateTime;

extends 'DBIx::Class::ResultSet';

sub load {
  my $self = shift;

  # accept an array, an array ref, or a hash. We'll assume the values in the
  # lists are in the correct order for the table, then turn them into a hash by
  # zipping them with the column names
  my $upload;
  if ( ref $_[0] eq 'HASH' ) {
    $upload = $_[0];
  }
  else {
    my @columns = $self->result_source->columns;
    my @values = ref $_[0]
               ? @{ $_[0] }
               : @_;
    my %hash = mesh @columns, @values;
    $upload = \%hash;
  }

  # parse out the antimicrobial resistance data and put them into the uploads
  # hash so that they'll get inserted correctly in the child table
  my $amr = [];
  if ( $upload->{amr} ) {
    my $amr_string = delete $upload->{amr};
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

  $self->update_or_create( $upload, { key => 'primary' } );
}

__PACKAGE__->meta->make_immutable;

1;
