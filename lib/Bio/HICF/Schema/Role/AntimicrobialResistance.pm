use utf8;
package Bio::HICF::Schema::Role::AntimicrobialResistance;

# ABSTRACT: role carrying methods for the AntimicrobialResistance table

use Moose::Role;

requires qw(
  sample_id
  antimicrobial_name
  susceptibility
  mic
  equality
  method
  created_at
  deleted_at
);

#-------------------------------------------------------------------------------

=head1 METHODS

=head2 get_amr_string

Returns the antimicrobial resistance result as a string.

=cut

sub get_amr_string {
  my $self = shift;

  my $equality = $self->equality eq 'eq'
               ? ''
               : $self->equality;

  my $amr_string = $self->get_column('antimicrobial_name') . ';'
                 . $self->susceptibility . ';'
                 . $equality . $self->mic;

  $amr_string .= ';' . $self->method
    if defined $self->method;

  return $amr_string;
}

#-------------------------------------------------------------------------------

1;

