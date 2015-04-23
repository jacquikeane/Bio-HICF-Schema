use utf8;
package Bio::HICF::Schema::Result::Taxonomy;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Bio::HICF::Schema::Result::Taxonomy - The NCBI taxonomic tree.

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=item * L<DBIx::Class::PassphraseColumn>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "PassphraseColumn");

=head1 TABLE: C<taxonomy>

=cut

__PACKAGE__->table("taxonomy");

=head1 ACCESSORS

=head2 tax_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

NCBI taxonomy ID for the given node

=head2 name

  data_type: 'text'
  is_nullable: 0

Scientific name for the given node

=head2 lft

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

`Left` value for the modified pre-ordered traversal tree

=head2 rgt

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

`Right` value for the modified pre-ordered traversal tree

=head2 parent_tax_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

The NCBI taxonomy ID for the parent of the node

=cut

__PACKAGE__->add_columns(
  "tax_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "lft",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "rgt",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "parent_tax_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</tax_id>

=back

=cut

__PACKAGE__->set_primary_key("tax_id");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-04-23 14:45:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jkBsBCGtvzXagFwJ94yZhA


__PACKAGE__->meta->make_immutable;
1;
