use utf8;
package Bio::HICF::Schema::ResultSet::Sample;

use Moose;
use MooseX::NonMoose;
use Carp qw ( croak );

extends 'DBIx::Class::ResultSet';

sub BUILDARGS { $_[2] }
# see https://metacpan.org/pod/DBIx::Class::ResultSet#ResultSet-subclassing-with-Moose-and-similar-constructor-providers

#-------------------------------------------------------------------------------

# ABSTRACT: resultset for the sample table

=head1 METHODS

=head2 load_row($upload)

Loads a row into the C<sample> table using values from the supplied hash. The
hash should contain column values keyed on column names.

Further validation checks are applied before loading, such as confirming that
the tax ID and scientific name match. An exception is thrown if any of these
checks fail.

=cut

sub load_row {
  my ( $self, $upload ) = @_;

  croak 'not a valid row' unless ref $upload eq 'HASH';

  # check the taxonomy information

  # make sure the tax ID and scientific name agree
  $self->_taxonomy_name_check($upload);

  # check that the "specific_host" is a valid scientific name
  $self->_scientific_name_check($upload);

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
#- private methods -------------------------------------------------------------
#-------------------------------------------------------------------------------

# taxonomy ID/scientific name consistency check
sub _taxonomy_name_check {
  my ( $self, $upload ) = @_;

  my $tax_id = $upload->{tax_id};
  my $name   = $upload->{scientific_name};

  # we can only validate taxonomy ID/name if we have both
  return if (    (     defined $tax_id and not defined $name )
              or ( not defined $tax_id and     defined $name ) );

  my $schema = $self->result_source->schema;

  # look up the tax ID and scientific name in the taxonomy table
  my $lookup_tax_id = $schema->resultset('Taxonomy')
                             ->find( { name => $name },
                                     { key => 'name_uq' } )
                             ->tax_id;
  my $lookup_name   = $schema->resultset('Taxonomy')
                             ->find( { tax_id => $tax_id },
                                     { key => 'primary' } )
                             ->name;

  if ( $tax_id != $lookup_tax_id or
       $name   ne $lookup_name ) {
    croak 'taxonomy ID and scientific name do not match';
  }
}

#-------------------------------------------------------------------------------

# check specific host is a valid scientific name
sub _scientific_name_check {
  my ( $self, $upload ) = @_;

  my $name = $upload->{specific_host};

  return unless defined $name;

  my $rs = $self->result_source
                ->schema
                ->resultset('Taxonomy')
                ->find( { name => $name },
                        { key => 'name_uq' } );

  croak 'species name in "specific_host" is not found in the taxonomy tree'
    unless defined $rs;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;
