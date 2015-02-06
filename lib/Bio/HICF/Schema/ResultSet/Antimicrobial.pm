use utf8;
package Bio::HICF::Schema::ResultSet::Antimicrobial;

use Moose;
use MooseX::NonMoose;
use MooseX::Params::Validate;

use Carp qw ( croak );
use Bio::Metadata::Types;

extends 'DBIx::Class::ResultSet';

sub BUILDARGS { $_[2] }
# see https://metacpan.org/pod/DBIx::Class::ResultSet#ResultSet-subclassing-with-Moose-and-similar-constructor-providers

#-------------------------------------------------------------------------------

# ABSTRACT: resultset for the antimicrobial table

=head1 METHODS

=head2 load_antimicrobial($am_name)

Loads a new antimicrobial compound name into the C<antimicrobial> table.

=cut

sub load_antimicrobial {
  my $self = shift;
  my ( $am_name ) = pos_validated_list(
    \@_,
    { isa => 'Bio::Metadata::Types::AntimicrobialName' },
  );

  $self->find_or_create(
    { name => $am_name },
    { key => 'primary' }
  );
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;
