use utf8;
package Bio::HICF::User::Result::MidasSession;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Bio::HICF::User::Result::MidasSession - Session data for the MIDAS website

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

=head1 TABLE: C<midas_session>

=cut

__PACKAGE__->table("midas_session");

=head1 ACCESSORS

=head2 id

  data_type: 'varchar'
  is_nullable: 0
  size: 72

Unique ID for the session.

=head2 session_data

  data_type: 'longtext'
  is_nullable: 1

The data stored in the session, encoded as a single string

=head2 expires

  data_type: 'integer'
  is_nullable: 1

The expiry date/time of the session, given as in epoch seconds

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "varchar", is_nullable => 0, size => 72 },
  "session_data",
  { data_type => "longtext", is_nullable => 1 },
  "expires",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-05-27 12:12:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uXnMAvur9xMfU08cfVizUA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
