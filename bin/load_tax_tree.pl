# !env perl
#
# load_tax_tree.pl
# jt6 20150204 WTSI

# ABSTRACT: loads the NCBI taxonomy tree
# PODNAME: load_tax_tree.pl

use strict;
use warnings;

use Getopt::Long::Descriptive;
use Pod::Usage;
use Config::General;
use TryCatch;
use Carp qw( croak );

use Bio::HICF::Schema;
use Bio::Metadata::TaxTree;

#-------------------------------------------------------------------------------
# boilerplate

# define the accepted options
my ( $opt, $usage ) = describe_options(
  'load_tax_tree.pl %o',
  [ 'config|c=s', 'path to the configuration file' ],
  [ 'help|h',    'print usage message' ],
);

# show the POD as usage information
pod2usage( { -verbose => 2, -exitval => 0 } )
  if $opt->help;

# take the paths to the config either from the options or from an environment
# variable
my $config_file = $opt->config || $ENV{HICF_CONFIG};

_usage('ERROR: you must specify a configuration file')
  unless defined $config_file;

_usage("ERROR: no such configuration file ($config_file)")
  unless -f $config_file;

#-------------------------------------------------------------------------------
# load configuration

my $cg;
try {
  $cg = Config::General->new($config_file);
}
catch ( $e ) {
  croak "ERROR: there was a problem reading the config file ($config_file): $e";
}

my %config = $cg->getall;

#-------------------------------------------------------------------------------

# read the names.dmp and nodes.dmp to generate the tree nodes
my $tt = Bio::Metadata::TaxTree->new( names_file => $config{taxdump}->{names},
                                      nodes_file => $config{taxdump}->{nodes} );

# number the nodes to form the in-memory tree
$tt->build_tree;

# get a database connection
my $schema = Bio::HICF::Schema->connect( @{ $config{database}->{connect_info} } );

# load it
try {
  $schema->load_tax_tree($tt);
}
catch ( $e ) {
  croak "ERROR: there was a problem loading the tax tree:\n$e";
}

exit 0;

#-------------------------------------------------------------------------------
#- functions -------------------------------------------------------------------
#-------------------------------------------------------------------------------

sub _usage {
  my $msg = shift;

  print STDERR "$msg\n";
  print $usage->text;
  exit 1;
}

#-------------------------------------------------------------------------------

__END__

=head1 SYNOPSIS

 shell% load_tax_tree.pl -c hicf_script_configuration.conf

=head1 DESCRIPTION

This script reads the NCBI taxonomy tree dump files (C<names.dmp> and
C<nodes.dmp>) and loads the resulting tree into the C<taxonomy> table in the
HICF sample database. The script requires one argument, the path to a
configuration file. The config file must specify the database connection
parameters (C<database>) and the paths to the two dump files (C<taxdump>).

Before loading the new taxonomy data, the C<taxonomy> table is first emptied.
If there is an error during loading, the script tries to roll back the
truncation and any subsequent loading.

=head1 OPTIONS

=over 4

=item -h --help

display help text

=item -c --config

configuration file. Required.

=back

=head1 SEE ALSO

L<Bio::Metadata::TaxTree>
L<Bio::HICF::Schema>

=head1 CONTACT

path-help@sanger.ac.uk

=cut

