use utf8;
package Bio::HICF::Schema::Result::Taxonomy;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Bio::HICF::Schema::Result::Taxonomy

=head1 DESCRIPTION

Look-up table storing the NCBI tax IDs from the NCBI taxonomy tree.

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

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");

=head1 TABLE: C<taxonomy>

=cut

__PACKAGE__->table("taxonomy");

=head1 ACCESSORS

=head2 tax_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 lft

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 rgt

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 parent_tax_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-02-04 13:47:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8QzNOzUtj7oJ1pz2CNrZdA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
