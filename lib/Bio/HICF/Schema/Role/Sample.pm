
package Bio::HICF::Schema::Role::Sample;

# ABSTRACT: role carrying methods for the Sample table

use Moose::Role;

requires qw(
  sample_id
  manifest_id
  raw_data_accession
  sample_accession
  sample_description
  collected_at
  tax_id
  scientific_name
  collected_by
  source
  _collection_date
  _location
  _host_associated
  _specific_host
  _host_disease_status
  _host_isolation_source
  _patient_location
  _isolation_source
  _serovar
  _other_classification
  strain
  isolate
  withdrawn
  created_at
  updated_at
  deleted_at
);

use Carp qw(croak);

#-------------------------------------------------------------------------------

=head1 METHODS

=head2 fields

Returns a reference to a hash containing field values, keyed on field name.

=cut

sub fields {
  my $self = shift;

  my ( $values_list, $values_hash ) = $self->_get_values;
  return $values_hash;
}

#-------------------------------------------------------------------------------

=head2 field_values

Returns a reference to an array containing field values, in the order that they
are found in the checklist.

=cut

sub field_values {
  my $self = shift;

  my ( $values_list, $values_hash ) = $self->_get_values;
  return $values_list;
}

#-------------------------------------------------------------------------------

=head2 field_names

Returns a list of the fields in a sample, in the order in which they appear in
the checklist.

=cut

sub field_names {
  return [ qw(
    raw_data_accession
    sample_accession
    sample_description
    collected_at
    tax_id
    scientific_name
    collected_by
    source
    collection_date
    location
    host_associated
    specific_host
    host_disease_status
    host_isolation_source
    patient_location
    isolation_source
    serovar
    other_classification
    strain
    isolate
  ) ];
}

#-------------------------------------------------------------------------------
#- custom accessors ------------------------------------------------------------
#-------------------------------------------------------------------------------

=head2 collection_date(?$date)

Overrides the default accessor to provide checking for unknown values.

If C<$date> is given, it must be either an integer, in which case it is
interpreted as an epoch date (number of seconds since the unix epoch), or a
valid "unknown" term. An exception is thrown if the date does not meet one of
those two criteria.

If no date is given, the date value from the column is returned. This may be
either an epoch time integer or an unknown value. Use
L<Bio::HICF::Schema::Result::Sample::collection_date_dt|collection_date_dt>
to return the collection date as a L<DateTime> object.

=cut

sub collection_date {
  my ( $self, $date ) = @_;

  if ( defined $date ) {
    if ( $date =~ m/^(\d+)$/ or
         $self->result_source->schema->is_unknown($date) ) {
      return $self->_collection_date($date);
    }
    else {
      die "ERROR: not a valid date ($date)";
    }
  }

  return $self->_collection_date;
}

#-------------------------------------------------------------------------------

=head2 collection_date_dt(?$date)

=cut

# sub collection_date_dt {
#   my ( $self, $date ) = @_;
#
#   return $self->collection_date($date) if defined $date;
#
#
#   # croak 'ERROR: not a DateTime object' unless
# }

#-------------------------------------------------------------------------------

sub location {
  my $self = shift;

  return $self->_location(@_) if @_;

  ...
}

sub host_associated {
  my $self = shift;

  return $self->_host_associated(@_) if @_;

  ...
}

sub specific_host {
  my $self = shift;

  return $self->_specific_host(@_) if @_;

  ...
}

sub host_disease_status {
  my $self = shift;

  return $self->_host_disease_status(@_) if @_;

  ...
}

sub host_isolation_source {
  my $self = shift;

  return $self->_host_isolation_source(@_) if @_;

  ...
}

sub patient_location {
  my $self = shift;

  return $self->_patient_location(@_) if @_;

  ...
}

sub isolation_source {
  my $self = shift;

  return $self->_isolation_source(@_) if @_;

  ...
}

sub serovar {
  my $self = shift;

  return $self->_serovar(@_) if @_;

  ...
}

sub other_classification {
  my $self = shift;

  return $self->_other_classification(@_) if @_;

  ...
}


#-------------------------------------------------------------------------------
#- private methods -------------------------------------------------------------
#-------------------------------------------------------------------------------

sub _get_values {
  my $self = shift;

  my $values_list = [];
  my $values_hash = {};
  foreach my $field ( @{ $self->field_names } ) {
    my $value = $self->get_column($field);
    push @$values_list, $value;
    $values_hash->{$field} = $value;
  }
  my @amr_strings;
  foreach my $amr ( $self->antimicrobial_resistances ) {
    push @amr_strings, $amr->get_amr_string;
  }
  push @$values_list, join ',', @amr_strings;
  $values_hash->{antimicrobial_resistance} = join ',', @amr_strings;

  return ( $values_list, $values_hash );
}

#-------------------------------------------------------------------------------

1;
