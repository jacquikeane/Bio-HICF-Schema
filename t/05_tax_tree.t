
use strict;
use warnings;

use Test::More tests => 15;
use Test::DBIx::Class qw( :resultsets );
use Test::Exception;

# load the pre-requisite data
fixtures_ok 'main', 'installed fixtures';

my $tt = Bio::Metadata::TaxTree->new( names_file => 't/data/05_names.dmp', nodes_file => 't/data/05_nodes.dmp' );
$tt->build_tree;

lives_ok { Taxonomy->load($tt) } 'successfully loaded tax tree';
is( Taxonomy->count, 12, 'got expected number of rows' );

lives_ok { Taxonomy->load($tt) } 'successfully loaded tax tree a second time';
is( Taxonomy->count, 12, 'got expected number of rows' );

lives_ok { Taxonomy->load($tt, 5) } 'successfully loaded with a slice size specified';
is( Taxonomy->count, 12, 'got expected number of rows' );

my $node = Taxonomy->find(8);
my @path = Taxonomy->search( { lft => { '<=', $node->lft },
                               rgt => { '>=', $node->rgt } },
                             { order_by => [ qw( tax_id ) ] } );
is( scalar @path, 4, 'path search returns expected number of nodes' );
is( $path[1]->name, 'node four', 'found expected node in path' );
is( $path[2]->name, 'node six', 'found expected node in path' );

$node = Taxonomy->find(4);
my @tree = Taxonomy->search( { lft => { '>', $node->lft },
                               rgt => { '<', $node->rgt } },
                             { order_by => [ qw( tax_id ) ] } );
is( scalar @tree, 4, 'subtree search returns expected number of nodes' );
is( $tree[0]->name, 'node six', 'found expected node in tree' );
is( $tree[3]->name, 'leaf 2', 'found expected node in tree' );

# hack the tree to add a duplicate row, so that we can test the failure mode of
# the loader
my $tree_node = Tree::Simple->new(
  {
    tax_id        => 12,
    name          => 'leaf 5',
    lft           => 3,
    rgt           => 4,
    parent_tax_id => 2,
  }
);
$tt->nodes->[13] = $tree_node;

throws_ok { Taxonomy->load($tt) } qr/loading the tax tree failed.*?rolled back/,
  'error and roll back with tree with duplicate nodes';
is( Taxonomy->count, 12, 'table still has expected number of rows' );

$DB::single = 1;

done_testing;

__END__

# loaded tree should look like:
tree
└── root (1, 24)
    ├── node two (2, 5)
    │   └── leaf 5 (3, 4)
    ├── node three (6, 9)
    │   └── leaf 4 (7, 8)
    ├── node four (10, 19)
    │   ├── node six (11, 14)
    │   │   └── leaf 1 (12, 13)
    │   └── node seven (15, 18)
    │       └── leaf 2 (16, 17)
    └── node five (20, 23)
        └── leaf 3 (21, 22)
