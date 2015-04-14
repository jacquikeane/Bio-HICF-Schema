
package Bio::HICF::Schema::Role::Sample;

# ABSTRACT: role carrying methods for the Sample table

use Moose::Role;
use DateTime;
use DateTime::Format::ISO8601;
use Try::Tiny;

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
  serovar
  other_classification
  strain
  isolate
  withdrawn
  created_at
  deleted_at
);

use Carp qw(croak);

#-------------------------------------------------------------------------------

=head1 METHODS

=head2 is_deleted

Returns 1 if this sample has been deleted, 0 otherwise.

=cut

sub is_deleted {
  my $self = shift;

  return defined $self->deleted_at ? 1 : 0;
}

#-------------------------------------------------------------------------------

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

If C<$date> is supplied, it must be either an integer, in which case it is
interpreted as an epoch time (number of seconds since the unix epoch), or a
valid "unknown" term. An exception is thrown if C<$date> is neither.

If C<$date> is not supplied, the date value from the column is returned. This
may be either an epoch time integer or an unknown value. Use
L<Bio::HICF::Schema::Result::Sample::collection_date_dt|collection_date_dt> to
return the collection date as a L<DateTime> object.

=cut

sub collection_date {
  my ( $self, $date ) = @_;

  if ( defined $date ) {
    if ( $date =~ m/^(\d+)$/ or
         $self->result_source->schema->is_accepted_unknown($date) ) {
      return $self->_collection_date($date);
    }
    else {
      die "ERROR: not a valid date or 'unknown' value ($date)";
    }
  }

  return $self->_collection_date;
}

#-------------------------------------------------------------------------------

=head2 collection_date_dt(?$date)

Overrides the default accessor to handle dates as L<DateTime> objects.

If C<$date> is supplied, we check if it's a L<DateTime> object and, if so,
convert it to an epoch time for storage. If it's not a L<DateTime>, we check if
it's an epoch time or an accepted "unknown" value and store it if so. If it's
neither an epoch time nor "unknown", an exception is thrown.

If C<$date> is not supplied and the stored collection date is a real date and
not "unknown", the stored date is returned as a L<DateTime> object. If the
stored date is "unknown" the return value is C<undef>. If there simply is no
stored date (shouldn't happen), the return value is C<undef>.

=cut

sub collection_date_dt {
  my ( $self, $date ) = @_;

  my $schema = $self->result_source->schema;
  my $rv;

  if ( $date ) {
    # validate and store the supplied date
    if ( ref $date eq 'DateTime' ) {
      $rv = $self->_collection_date($date->epoch);
    }
    elsif ( $date =~ m/^\d+$/ or
            $schema->is_accepted_unknown($date) ) {
      $rv = $self->_collection_date($date);
    }
    else {
      my $epoch;
      try {
        my $dt = DateTime::Format::ISO8601->parse_datetime($date);
        $epoch = $dt->epoch;
      } catch {
        die "ERROR: not unknown and can't convert to an epoch time ($date)";
      };
      $rv = $self->_collection_date($epoch);
    }
  }
  else {
    # we weren't handed a date to store, so return the currently stored date
    my $stored_date = $self->_collection_date;

    if ( not defined $stored_date ) {
      $rv = undef;
    }
    elsif ( $schema->is_accepted_unknown($stored_date) ) {
      # explicitly ignore "unknown"
      $rv = undef;
    }
    elsif ( $stored_date =~ m/^\d+$/ ) {
      # convert the epoch time in the database into a DateTime object
      $rv = DateTime->from_epoch(epoch => $stored_date);
    }
    else {
      die "ERROR: don't know what is stored in the collection_date column ($stored_date)";
    }
  }

  return $rv;
}

#-------------------------------------------------------------------------------

=head2 location(?$location)

Overrides the default accessor to handle unknowns.

If C<$location> is supplied, we check if it's a valid GAZ ontology term, i.e.
it must be found in the GAZ ontology table, or if it's an accepted "unknown".
In either case the value is stored. If the value is not a valid term or an
accepted unknown, an exception will be thrown.

If C<$location> is not supplied, the stored location is returned.

=cut

sub location {
  my ( $self, $location ) = @_;

  my $schema = $self->result_source->schema;

  # if there's no value to store, immediately return whatever we have stored
  return $self->_location unless defined $location;

  # if the supplied value is "unknown", store it immediately
  return $self->_location($location) if $schema->is_accepted_unknown($location);

  die "ERROR: not a valid location or 'unknown' ($location)"
    unless $location =~ m/^GAZ:\d+$/;

  # if this looks like an ontology term, look it up in the GAZ ontology
  my $term = $schema->resultset('Gazetteer')->find($location);

  die "ERROR: can't find location in Gazetteer ontology ($location)"
    unless defined $term;

  # location appears to be a valid ontology term; store it
  return $self->_location($location);
}

#-------------------------------------------------------------------------------

=head2 host_associated(?$ha)

Overrides the default accessor to handle unknowns and various expressions of
"true" or "false".

If C<$ha> is supplied, we check if it's a valid boolean or an accepted
"unknown" value. A valid boolean is one of: C<0>, C<1>, C<no>, C<yes>,
C<false>, C<true>. Passing in any other value results in an exception being
thrown. Boolean values are converted to either C<0> or C<1> for storage in the
database.

If C<$ha> is not supplied, the stored value is returned. B<Note> that even
if you try to store "yes", the stored value will be returned as C<1>. If the
stored value is an accepted "unknown", it is returned verbatim.

=cut

sub host_associated {
  my ( $self, $ha ) = @_;

  # if there's no value to store, immediately return whatever we have stored
  return $self->_host_associated unless defined $ha;

  # if the supplied value is "unknown", store it immediately
  return $self->_host_associated($ha)
    if $self->result_source->schema->is_accepted_unknown($ha);

  # at this point we must have a value that should represent true or false
  return $self->_host_associated(0) if $ha =~ m/^(0|no|false)$/;
  return $self->_host_associated(1) if $ha =~ m/^(1|yes|true)$/;

  # and if not, throw an exception
  die 'ERROR: host_associated must be true or false';
}

#-------------------------------------------------------------------------------

=head2 specific_host(?$sh)

Overrides default accessor to handle unknowns.

If C<$sh> is supplied, we check that it's either an accepted unknown value or
that it is found as a scientific name in the taxonomy tree. If the supplied
value is neither unknown nor a valid name, an exception is thrown.

If C<$sh> is not supplied, the stored value is returned.

=cut

sub specific_host {
  my ( $self, $sh ) = @_;

  my $schema = $self->result_source->schema;

  # if there's no value to store, immediately return whatever we have stored
  return $self->_specific_host unless $sh;

  # if the supplied value is "unknown", store it immediately
  return $self->_specific_host($sh) if $schema->is_accepted_unknown($sh);

  # if this looks like an ontology term, look it up in the GAZ ontology
  my $name_rs = $schema->resultset('Taxonomy')->search( {name => $sh}, {});

  die "ERROR: not an accepted unknown and can't find name in taxonomy tree ($sh)"
    unless defined $name_rs && $name_rs->count;

  return $self->_specific_host($sh);
}

#-------------------------------------------------------------------------------

=head2 host_disease_status(?$hds)

Overrides default accessor to handle unknowns.

If C<$hds> is supplied, we check that it's either an accepted unknown value or
that it is one of "healthy", "diseased", or "carriage". If the supplied value
is neither unknown nor a valid term, an exception is thrown.

If C<$hds> is not supplied, the stored value is returned.

=cut

sub host_disease_status {
  my ( $self, $hds ) = @_;

  # if there's no value to store, immediately return whatever we have stored
  return $self->_host_disease_status unless defined $hds;

  # if the supplied value is "unknown", store it immediately
  return $self->_host_disease_status($hds)
    if $self->result_source->schema->is_accepted_unknown($hds);

  # at this point we must have a value that should be one of the allowed values
  return $self->_host_disease_status($hds)
    if $hds =~ m/^(healthy|diseased|carriage)$/;

  # and if not, throw an exception
  die 'ERROR: host_disease_status must be "healthy", "diseased", "carriage" or an accepted unknown value';
}

#-------------------------------------------------------------------------------

=head2 host_isolation_source(?$his)

Overrides default accessor to handle unknowns.

If C<$his> is supplied, we check that it's either an accepted unknown value or
that it is found in the Brenda ontology. If the supplied value is neither
unknown nor a valid term, an exception is thrown.

If C<$his> is not supplied, the stored value is returned.

=cut

sub host_isolation_source {
  my ( $self, $his ) = @_;

  my $schema = $self->result_source->schema;

  # if there's no value to store, immediately return whatever we have stored
  return $self->_host_isolation_source unless defined $his;

  # if the supplied value is "unknown", store it immediately
  return $self->_host_isolation_source($his)
    if $schema->is_accepted_unknown($his);

  die "ERROR: not a valid Brenda ontology term or 'unknown' ($his)"
    unless $his =~ m/^BTO:\d+$/;

  # this looks like an ontology term; look it up in the ontology
  my $term = $schema->resultset('Brenda')->find($his);

  die "ERROR: can't find host_isolation_source in Brenda ontology ($his)"
    unless defined $term;

  # value appears to be a valid ontology term; store it
  return $self->_host_isolation_source($his);
}

#-------------------------------------------------------------------------------

=head2 patient_location(?$location)

Overrides default accessor to handle unknowns.

If C<$location> is supplied, we check that it's either an accepted unknown
value or that it is either "inpatient" or "community". If the supplied value is
neither unknown nor a valid term, an exception is thrown.

If C<$location> is not supplied, the stored value is returned.

=cut

sub patient_location {
  my ( $self, $pl ) = @_;

  # if there's no value to store, immediately return whatever we have stored
  return $self->_patient_location unless defined $pl;

  # if the supplied value is "unknown", store it immediately
  return $self->_patient_location($pl)
    if $self->result_source->schema->is_accepted_unknown($pl);

  # at this point we have a value that should be one of the allowed values...
  return $self->_patient_location($pl) if $pl =~ m/^(inpatient|community)$/;

  # ... and if not, throw an exception
  die 'ERROR: patient_location must be "inpatient", "community", or an accepted unknown value';
}

#-------------------------------------------------------------------------------

=head2 isolation_source(?$is)

Overrides default accessor to handle unknowns.

If C<$is> is supplied, we check that it's either an accepted unknown value or
that it is found in the EnvO ontology. If the supplied value is neither unknown
nor a valid term, an exception is thrown.

If C<$is> is not supplied, the stored value is returned.

=cut

sub isolation_source {
  my ( $self, $is ) = @_;

  my $schema = $self->result_source->schema;

  # if there's no value to store, immediately return whatever we have stored
  return $self->_isolation_source unless defined $is;

  # if the supplied value is "unknown", store it immediately
  return $self->_isolation_source($is)
    if $schema->is_accepted_unknown($is);

  die "ERROR: not a valid EnvO ontology term or 'unknown' ($is)"
    unless $is =~ m/^ENVO:\d+$/;

  # if this looks like an ontology term, look it up in the GAZ ontology
  my $term = $schema->resultset('Envo')->find($is);

  die "ERROR: can't find isolation_source in EnvO ontology ($is)"
    unless defined $term;

  # value appears to be a valid ontology term; store it
  return $self->_isolation_source($is);
}

#-------------------------------------------------------------------------------

# if we decide to lock down the format of other_classification sometime, we'll
# need to add an override here for it

# sub other_classification {
#   my $self = shift;
#
#   return $self->_other_classification(@_);
# }

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
