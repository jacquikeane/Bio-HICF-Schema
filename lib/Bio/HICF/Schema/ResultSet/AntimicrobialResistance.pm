use utf8;
package Bio::HICF::Schema::ResultSet::AntimicrobialResistance;

use Moose;
use MooseX::NonMoose;

extends 'DBIx::Class::ResultSet';

sub BUILDARGS { $_[2] }
# see https://metacpan.org/pod/DBIx::Class::ResultSet#ResultSet-subclassing-with-Moose-and-similar-constructor-providers

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;
