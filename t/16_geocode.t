
use strict;
use warnings;

use Test::More;
use Test::CacheFile;
use Test::Exception;
use Test::Script::Run;
use Test::MockModule;
use File::Path qw(make_path remove_tree);
use File::Copy qw(copy move);
use File::Find::Rule;
use Cwd;

use Test::DBIx::Class {
  connect_info => [ 'dbi:SQLite:dbname=test.db', '', '' ],
}, qw( :resultsets );

# load the pre-requisite data and THEN turn on foreign keys
fixtures_ok 'main', 'installed fixtures';

my $preload = sub {
  my ( $storage, $dbh, @other_args ) = @_;
  $dbh->do( 'PRAGMA foreign_keys = ON' );
};

lives_ok { Schema->storage->dbh_do($preload) } 'successfully turned on "foreign_keys" pragma';

#-------------------------------------------------------------------------------

BEGIN { use_ok( 'Bio::HICF::Geocoder' ) }

$ENV{HICF_SCRIPT_CONFIG} = 't/data/16_script.conf';

throws_ok { Bio::HICF::Geocoder->new }
  qr//,
  'must supply an API key';

throws_ok { Bio::HICF::Geocoder->new( api_key => 'notvalid' ) }
  qr//,
  'not a valid API key';

my $g = new_ok( 'Bio::HICF::Geocoder' => [ api_key => $ENV{HICF_GOOGLE_API_KEY} ] );

# should have two distinct locations in the sample table, one with lat/long
# values, one without
is Sample->count,   2, 'two samples to geo-locate';
is Location->count, 1, 'one location already found';

# location finding
my $locations;
lives_ok { $locations = $g->find_unknown_locations } 'no error when finding locations';
is scalar @$locations, 1, 'got one new location to find';
is $locations->[0], 'GAZ:00489637', 'got expected location';

# mock out the LWP::UserAgent object, so that we don't actually need to call
# the API. This lets us test the handling of errors and failures, such as when
# we hit the API quota limits
my $successful_api_response = join '', <DATA>;

my $r;
my $mocked_ua = Test::MockModule->new('LWP::UserAgent');
$mocked_ua->mock('get', sub { return $r } );

# geocoding a location

# test error handling
$r = HTTP::Response->new(500, 'INTERNAL SERVER ERROR', [], $successful_api_response );
throws_ok { $g->_geocode_location('x') }
  qr/geocoding failed/,
  'error with bad response';

my $failed_api_response = $successful_api_response;
$failed_api_response =~ s/"status" : "OK"/"status" : "OVER_QUERY_LIMIT"/;

$r = HTTP::Response->new(200, 'OK', [], $failed_api_response );
throws_ok { $g->_geocode_location('x') }
  qr/reached API query limit/,
  'error with API query limit';

# successful response
$r = HTTP::Response->new(200, 'OK', [], $successful_api_response );
my ( $lat, $lng );
lives_ok { ( $lat, $lng ) = $g->_geocode_location('University of Oxford') }
  'no error getting lat/long for location';

is $lat, 51.7566341, 'latitude is as expected';
is $lng, -1.2547037, 'longitude is as expected';

# GAZ:00444180: WTSI 52.078972,   0.187583
# GAZ:00489637: UoO  51.7566341, -1.2547037

# geocoding a GAZ term
lives_ok { $g->geocode(['GAZ:00489637']) }
  'no error geocoding new term';
is Location->count, 2, 'two locations geocoded';

lives_ok { $g->geocode(['GAZ:00489637']) }
  'no error geocoding same term again';
is Location->count, 2, 'still two locations geocoded';
is Location->find('GAZ:00444180')->lat, 52.078972, 'got expected latitude for WTSI';
is Location->find('GAZ:00489637')->lat, 51.7566341, 'got expected latitude for UoO';

done_testing;

__DATA__
{
  "results" : [
     {
       "address_components" : [
         {
           "long_name" : "University of Oxford",
           "short_name" : "University of Oxford",
           "types" : [ "establishment" ]
         },
         {
           "long_name" : "University Offices",
           "short_name" : "University Offices",
           "types" : [ "premise" ]
         },
         {
           "long_name" : "Wellington Square",
           "short_name" : "Wellington Square",
           "types" : [ "route" ]
         },
         {
           "long_name" : "Oxford",
           "short_name" : "Oxford",
           "types" : [ "locality", "political" ]
         },
         {
           "long_name" : "Oxford",
           "short_name" : "Oxford",
           "types" : [ "postal_town" ]
         },
         {
           "long_name" : "Oxfordshire",
           "short_name" : "Oxfordshire",
           "types" : [ "administrative_area_level_2", "political" ]
         },
         {
           "long_name" : "United Kingdom",
           "short_name" : "GB",
           "types" : [ "country", "political" ]
         },
         {
           "long_name" : "OX1 2JD",
           "short_name" : "OX1 2JD",
           "types" : [ "postal_code" ]
         }
       ],
       "formatted_address" : "University Offices, University of Oxford, Wellington Square, Oxford, Oxford OX1 2JD, UK",
       "geometry" : {
         "bounds" : {
           "northeast" : {
             "lat" : 51.7773131,
             "lng" : -1.213425
           },
           "southwest" : {
             "lat" : 51.7461504,
             "lng" : -1.2720512
           }
         },
         "location" : {
           "lat" : 51.7566341,
           "lng" : -1.2547037
         },
         "location_type" : "APPROXIMATE",
         "viewport" : {
           "northeast" : {
             "lat" : 51.7721451,
             "lng" : -1.2357408
           },
           "southwest" : {
             "lat" : 51.7461504,
             "lng" : -1.2720512
           }
         }
       },
       "place_id" : "ChIJW0iM76nGdkgR7a8BoIMY_9I",
       "types" : [ "university", "establishment" ]
     }
   ],
   "status" : "OK"
}
