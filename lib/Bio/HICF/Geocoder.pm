use utf8;
package Bio::HICF::Geocoder;

# ABSTRACT: convert Gazetteer ontology terms into longitude and latitude
# jt6 20150421 WTSI

use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

use Try::Tiny;
use Config::General;
use LWP::UserAgent;
use JSON;

use Bio::HICF::Schema;

#---------------------------------------

=head1 ATTRIBUTES

=attr base_uri

Base URI for geocoding API.
=cut

has base_uri => (
  is      => 'ro',
  default => 'https://maps.googleapis.com/maps/api/geocode/json',
);

#---------------------------------------

=attr api_key

Google API key.

=cut

subtype 'APIKey',
  as      'Str',
  where   { m/^[A-Z0-9\-]{39}$/i },
  message { "'$_' is not a valid Google API key" };

has 'api_key' => (
  is       => 'rw',
  isa      => 'APIKey',
  required => 1,
);

#---------------------------------------

=attr config

A hashref containing the script configuration parameters. Loaded from the file
specified by the environment variable C<HICF_SCRIPT_CONFIG>. An exception is
thrown if the environment variable is not set or if the file pointed to by that
variable can't be read by L<Config::General>.

We enable variable interpolation in C<Config::General>, so you can use
environment variables to configure the location from outside the config file,
if required. See the test files for an example.

=cut

has config => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub {
    my $self = shift;

    die 'ERROR: must specify a script configuration file (set $HICF_SCRIPT_CONFIG)'
      unless defined $ENV{HICF_SCRIPT_CONFIG};
    die "ERROR: can't find config file specified by environment variable ($ENV{HICF_SCRIPT_CONFIG})"
      unless -f $ENV{HICF_SCRIPT_CONFIG};

    my $cg;
    try {
      $cg = Config::General->new(
        -ConfigFile      => $ENV{HICF_SCRIPT_CONFIG},
        -InterPolateEnv  => 1,
        -InterPolateVars => 1,
      );
    }
    catch {
      die "ERROR: there was a problem reading the script configuration: $_";
    };
    my %config = $cg->getall;

    # Config::General seems happy to read any old cruft, so we need to check
    # the resulting hash and make sure its contents looks right. This is a bit
    # crude, but it might catch some problems.
    die 'ERROR: the loaded script config is not valid'
      unless exists $config{database};

    return \%config;
  },
);

#---------------------------------------

=attr ua

L<LWP::UserAgent> object. B<Note> that we call C<env_proxy> on the user
agent before returning it.

=cut

has 'ua' => (
  is      => 'ro',
  writer  => '_set_ua',
  default => sub {
    my $ua = LWP::UserAgent->new;
    $ua->env_proxy;
    return $ua;
  },
);

#---------------------------------------

=attr schema

Database connection object (L<Bio::HICF::Schema>).

=cut

has schema => (
  is      => 'ro',
  isa     => 'Bio::HICF::Schema',
  lazy    => 1,
  default => sub {
    my $self         = shift;
    my $connect_info = $self->config->{database}->{connect_info};
    return Bio::HICF::Schema->connect(@$connect_info);
  },
);

#-------------------------------------------------------------------------------
#- methods ---------------------------------------------------------------------
#-------------------------------------------------------------------------------

=head1 METHODS

=head2 find_unknown_locations

Finds the locations in the C<sample> table that have no C<gaz_term> in the
C<location> table.

=cut

sub find_unknown_locations {
  my $self = shift;

  # we should be able to do this nicely with a single query, provided we can
  # add the appropriate relationships to the table classes. Unfortunately,
  # because we have to allow "unknown" in sample.location, we can't add a
  # foreign key to link sample to location. We could instead add the
  # relationship the other way, linking location to sample, but that requires
  # a right join, which isn't supported by SQLite, so we can't do tests...
  # Instead, we'll just do the join here in code. Ugly.

  # get a list of the unique GAZ terms from the sample table
  my $all_locations = $self->schema->resultset('Sample')->search(
    { },
    {
      columns  => ['location'],
      group_by => ['location'],
    }
  );

  # get a list of the locations that we've already geocoded
  my @all_geocoded_locations = $self->schema->resultset('Location')->search(
    { },
    { }
  );

  # hash the geocoded locations, so we can quickly look up whether we've
  # already geocoded a given sample location
  my %geocoded_locations = map { $_->gaz_term => 1 } @all_geocoded_locations;

  my @unknown_location_terms = ();

  while ( my $location = $all_locations->next ) {
    my $term = $location->location;
    push @unknown_location_terms, $term
      unless exists $geocoded_locations{$term};
  }

  return \@unknown_location_terms;
}

#-------------------------------------------------------------------------------

=head2 geocode($unknown_locations)

Attempts to find latitude and longitude values for the GAZ ontology terms.
C<$unknown_locations> should be a reference to an array containing the GAZ
terms to geocode. The GAZ terms are converted into locations string by looking
them up in the C<gazetteer> table in the database.

Throws an exception if there is a problem submitting the REST request to the
Google geocoding API. Throws an exception if the owner of the API key has
exceeded Google's usage limits.

Prints a warning if the geocoding query returned multiple results; in this case
the latitude and longitude values in the first result will be returned.

Loads the resulting latitude and longitude values into the C<location> table.

=cut

sub geocode {
  my ( $self, $unknown_locations ) = @_;

  TERM: foreach my $term ( @$unknown_locations ) {

    if ( $term !~ m/^GAZ:\d{8}$/ ) {
      warn "WARNING: '$term' is not a valid GAZ ontology term";
      next TERM;
    }

    # convert the GAZ term into a location description, which we can then hand
    # off to the Google geocoding API
    my $location = $self->schema->resultset('Gazetteer')->find($term);

    unless ( defined $location ) {
      warn "WARNING: couldn't find term '$term' in the gazetteer";
      next TERM;
    }

    my ( $lat, $lng ) = $self->_geocode_location($location->description);

    # we might not actually have values here...
    unless ( defined $lat and defined $lng ) {
      warn "WARNING: we couldn't find latitude/longitude vales for '$term' ($location)";
      next TERM;
    }

    # given both values, load them
    my $latlng = $self->schema->resultset('Location')->find_or_create(
      {
        gaz_term => $term,
        lat      => $lat,
        lng      => $lng,
      }
    );
  }
}

#-------------------------------------------------------------------------------
#- private methods -------------------------------------------------------------
#-------------------------------------------------------------------------------

# attempts to find latitude and longitude values for the supplied location
# string

sub _geocode_location {
  my ( $self, $location ) = @_;

  my ( $lat, $lng );

  my $uri = URI->new($self->base_uri);
  $uri->query_form(api_key => $self->api_key, address => $location);

  # query the API
  my $res = $self->ua->get($uri);

  die "ERROR: geocoding failed for '$location': " . $res->status_line
    unless $res->is_success;

  # decode the (hopefully) JSON response and see what Google's status was
  my $json = $res->decoded_content;
  my $geocoding_response = decode_json $json;

  if ( $geocoding_response->{status} ne 'OK' ) {
    my $status = $geocoding_response->{status};
    if ( $status eq 'OVER_QUERY_LIMIT' ) {
      die 'ERROR: reached API query limit';
    }
    elsif ( $status eq 'ZERO_RESULTS' ) {
      warn 'WARNING: no results for location';
      return;
    }
    else {
      die "ERROR: there was a problem with the geocoding request for '$location'";
    }
  }

  # it's possible to get multiple results for a given location. We'll warn if
  # that happens, but continue on and just return the lat/long from the first
  # match
  warn "WARNING: found multiple results for location"
    if scalar @{ $geocoding_response->{results} } > 1;

  my $latlng = $geocoding_response->{results}->[0]->{geometry}->{location};

  return ( $latlng->{lat}, $latlng->{lng} );
}

#-------------------------------------------------------------------------------

=head1 SEE ALSO

L<Bio::Metadata::Validator>

=head1 CONTACT

path-help@sanger.ac.uk

=cut

__PACKAGE__->meta->make_immutable;

1;

