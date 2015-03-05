use utf8;
package Bio::HICF::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-01-13 15:26:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/Tydb6euSFy7u3YcKYKMrA

# ABSTRACT: DBIC schema for the HICF repository

=head1 SYNOPSIS

 # read in a manifest
 my $c = Bio::Metadata::Config->new( config_file => 'hicf.conf' );
 my $r = Bio::Metadata::Reader->new( config => $c );
 my $m = $r->read_csv( 'hicf.csv' );

 # load it into the database
 my $schema = Bio::HICF::Schema->connect( $dsn, $username, $password );
 my @sample_ids = $schema->load_manifest($m);

=cut

use Carp qw( croak );
use Bio::Metadata::Validator;
use Bio::Metadata::TaxTree;
use List::MoreUtils qw( mesh );
use TryCatch;
use MooseX::Params::Validate;
use Email::Valid;

#-------------------------------------------------------------------------------

=head1 METHODS

=head2 load_manifest($manifest)

Loads the sample data in a L<Bio::Metadata::Manifest>. Returns a list of the
sample IDs for the newly inserted rows.

The database changes are made inside a transaction (see
L<DBIx::Class::Storage#txn_do>). If there is a problem during loading an
exception is throw and we try to roll back any database changes that have been
made. If the roll back fails, the error message will include the phrase "roll
back failed".

=cut

sub load_manifest {
  my ( $self, $manifest ) = @_;

  croak 'not a Bio::Metadata::Manifest'
    unless ref $manifest eq 'Bio::Metadata::Manifest';

  my $v = Bio::Metadata::Validator->new;

  croak 'ERROR: the data in the manifest are not valid'
    unless $v->validate($manifest);

  # build a transaction
  my @row_ids;
  my $txn = sub {

    # add a row to the manifest table
    my $rs = $self->resultset('Manifest')
                  ->find_or_create(
                    {
                      manifest_id => $manifest->uuid,
                      md5         => $manifest->md5,
                      config      => { config => $manifest->config->config_string }
                    },
                    { key => 'primary' }
                  );

    # load the sample rows
    my $field_names = $manifest->field_names;

    foreach my $row ( $manifest->all_rows ) {

      # zip the field names and values together to form a hash...
      my %upload = mesh @$field_names, @$row;

      # ... add the manifest ID...
      $upload{manifest_id} = $manifest->uuid;

      # ... and pass that hash to the ResultSet to load
      push @row_ids, $self->resultset('Sample')->load_row(\%upload);
    }

  };

  # run the transaction
  try {
    $self->txn_do( $txn );
  } catch ( $e ) {
    if ( $e =~ m/Rollback failed/ ) {
      croak "ERROR: there was an error when loading the manifest but roll back failed: $e";
    }
    else {
      croak "ERROR: there was an error when loading the manifest; changes have been rolled back: $e";
    }
  };

  return @row_ids;
}

#-------------------------------------------------------------------------------

=head2 get_manifest($manifest_id)

Returns a L<Bio::Metadata::Manifest> object for the specified manifest.

=cut

sub get_manifest {
  my ( $self, $manifest_id ) = @_;

  # create a B::M::Config object from the config string that we have stored for
  # this manifest
  my $config_rs = $self->resultset('Manifest')
                       ->search( { manifest_id => $manifest_id },
                                 { prefetch => [ 'config' ] } )
                       ->single;

  return unless $config_rs;

  my %config_args = ( config_string => $config_rs->config->config );
  if ( defined $config_rs->config->name ) {
    $config_args{config_name} = $config_rs->config->name;
  }

  my $c = Bio::Metadata::Config->new(%config_args);

  # get the values for the samples in the manifest and add them to a new
  # B::M::Manifest
  my $values = $self->get_samples($manifest_id);
  my $m = Bio::Metadata::Manifest->new( config => $c, rows => $values );

  return $m;
}

#-------------------------------------------------------------------------------

=head2 get_sample($sample_id)

Returns a reference to an array containing the field values for the specified
sample.

=cut

sub get_sample {
  my ( $self, $sample_id ) = @_;

  my $sample = $self->resultset('Sample')
                    ->find($sample_id);
  croak "ERROR: no sample with that ID ($sample_id)"
    unless defined $sample;

  my $values = $sample->field_values;
  croak "ERROR: couldn't get values for sample $sample_id"
    unless ( defined $values and scalar @$values );

  return $values;
}

#-------------------------------------------------------------------------------

=head2 get_samples(@args)

Returns a reference to an array containing the field values for the specified
samples, one sample per row. If the first element of C<@args> looks like a UUID,
it's assumed to be a manifest ID and the method returns the field data for all
samples in that manifest. Otherwise C<@args> is assumed to be a list of sample
IDs and the field data for each is return.

=cut

sub get_samples {
  my ( $self, @args ) = @_;

  my $samples;

  if ( $args[0] =~ m/^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$/i ) {
    # we were handed a manifest ID
    my $rs = $self->resultset('Sample')
                  ->search( { manifest_id => $args[0] },
                            { prefetch => 'antimicrobial_resistances' } );
    push @$samples, $_->field_values for ( $rs->all );
  }
  else {
    my $sample_ids = ( ref $args[0] eq 'ARRAY' )
                   ? $args[0]
                   : \@args;
    # we were handed a list of sample IDs
    push @$samples, $self->get_sample($_) for @$sample_ids;
  }

  return $samples;
}

#-------------------------------------------------------------------------------

=head2 load_antimicrobial($name)

Adds the specified antimicrobial compound name to the database. Throws an
exception if the supplied name is invalid, e.g. contains non-word characters.

=cut

sub load_antimicrobial {
  my ( $self, $name ) = @_;

  chomp $name;

  try {
    $self->resultset('Antimicrobial')->load_antimicrobial($name);
  } catch ( $e where { m/did not pass/ } ) {
    croak "ERROR: couldn't load '$name'; invalid antimicrobial compound name";
  };
}

#-------------------------------------------------------------------------------

=head2 load_antimicrobial_resistance(%amr)

Loads a new antimicrobial resistance test result into the database. See
L<Bio::HICF::Schema::ResultSet::AntimicrobialResistance::load_antimicrobial_resistance>
for details.

=cut

sub load_antimicrobial_resistance {
  my ( $self, %amr ) = @_;
  $self->resultset('AntimicrobialResistance')->load_antimicrobial_resistance(%amr);
}

#-------------------------------------------------------------------------------

=head2 load_tax_tree($tree, $?slice_size)

load the given tree into the taxonomy table.
See L<Bio::HICF::Schema::ResultSet::Taxonomy::load_tax_tree>.

=cut

sub load_tax_tree {
  my ( $self, $tree, $slice_size ) = @_;

  $self->resultset('Taxonomy')->load_tree($tree, $slice_size);
}

#-------------------------------------------------------------------------------

=head2 load_ontology($table, $file, $?slice_size)

load the given ontology file into the specified table. Requires the name of the
table to load, which must be one of "gazetteer", "envo", or "brenda".  Requires
the path to the ontology file to be loaded. Since the ontologies may be large,
the terms are loaded in chunks of 10,000 at a time. This "slice size" can be
overridden with the C<$slice_size> parameter.

B<Note> that the specified table is emptied before loading.

Throws exceptions if loading fails. If possible, the entire transaction,
including the table truncation and any subsequent loading, will be rolled back.
If roll back fails, the error message will contain the string C<roll back
failed>.

=cut

sub load_ontology {
  my $self = shift;
  my ( $table, $file, $slice_size ) = pos_validated_list(
    \@_,
    { isa => 'Bio::Metadata::Types::OntologyName' },
    { isa => 'Str' },
    { isa => 'Bio::Metadata::Types::PositiveInt', optional => 1 },
  );
  # TODO the error message that comes back from the validation call is dumb
  # TODO and ugly. Just validate the ontology name ourselves and throw a
  # TODO sensible error

  croak "ERROR: ontology file not found ($file)"
    unless ( defined $file and -f $file );

  open ( FILE, $file )
    or croak "ERROR: can't open ontology file ($file): $!";

  $slice_size ||= 10_000;
  my $rs_name = ucfirst $table;
  my $rs = $self->resultset($rs_name);

  # wrap this whole operation in a transaction
  my $txn = sub {

    # before we start, truncate the table
    $rs->delete;

    # walk the file and load it in chunks
    my $chunk   = [ [ 'id', 'description' ] ];  # loading chunk
    my $term    = [];                           # current term
    my $is_term = 0;                            # is the current block a [Term] ?
    my $n       = 1;                            # row counter

    while ( <FILE> ) {
      # make sure we're working with a [Term] and not, for example, a
      # [Typedef] block, which also have "id: ..." lines
      if ( m/^\[Term\]/ ) {
        $is_term = 1;
      }
      # if this *is* a [Term] block and we've found an ID, store it
      if ( m/^id: (.*?)$/ and $is_term ) {
        my $id = $1;
        croak "ERROR: found an invalid ontology term ID ($1)"
          unless $id =~ m/^[A-Z]+:\d+$/;
        push @$term, $id;
      }
      # and if this is a [Term] and we've found a name for it, store that too
      if ( m/^name: (.*)$/ and $is_term ) {
        push @$term, $1;
        push @$chunk, $term;

        # load the current set of terms every Nth term
        if ( $n % $slice_size == 0 ) {
          try {
            $rs->populate($chunk);
          } catch ( $e ) {
            croak "ERROR: there was a problem loading the '$table' table: $e";
          };
          # reset the chunk array
          $chunk = [ [ 'id', 'description' ] ];
        }
        $n++;

        # reset for the next [Term]
        $term = [];
        $is_term = 0;
      }
    }
    # load the last chunk
    if ( scalar @$chunk > 1 ) {
      try {
        $rs->populate($chunk);
      } catch ( $e ) {
        croak "ERROR: there was a problem loading the '$table' table: $e";
      };
    }
  };

  # execute the transaction
  try {
    $self->txn_do( $txn );
  } catch ( $e ) {
    if ( $e =~ m/Rollback failed/ ) {
      croak "ERROR: loading the ontology failed but roll back failed ($e)";
    }
    else {
      croak "ERROR: loading the ontology failed and the changes were rolled back ($e)";
    }
  };
}

#-------------------------------------------------------------------------------

=head2 add_external_resource($resource_spec}

Add a record to the C<external_resources> table to record the addition of a new
external resource. The C<$resource_spec> hash must contain the four required
keys plus, optionally, a version:

=over 4

=item name

the name of the resource

=item source

the source of the resources, typically the canonical URL

=item retrieved_at

a L<DateTime> object giving the time that the resource file was retrieved from
the canonical source

=item checksum

an MD5 checksum for the resource file, typically generated using
L<Digest::MD5::md5sum>.

=item version

a version number for the resource, if available. Optional.

=back

=cut

sub add_external_resource {
  my ( $self, $resource_spec ) = @_;

  croak 'ERROR: one of the required fields is missing'
    unless ( defined $resource_spec->{name} and
             defined $resource_spec->{source} and
             defined $resource_spec->{retrieved_at} and
             defined $resource_spec->{checksum} );

  # format the retrieved at DateTime object
  # (see https://metacpan.org/pod/DBIx::Class::Manual::Cookbook#Formatting-DateTime-objects-in-queries)
  if ( ref $resource_spec->{retrieved_at} eq 'DateTime' ) {
    my $ra = $resource_spec->{retrieved_at};
    my $dtf = $self->storage->datetime_parser;
    my $formatted_ra = $dtf->format_datetime($ra);
    $resource_spec->{retrieved_at} = $formatted_ra;
  }

  my $resource = $self->resultset('ExternalResource')
                      ->find_or_new( $resource_spec );

  croak 'ERROR: this resource already exists'
    if $resource->in_storage;

  $resource->insert;
}

#-------------------------------------------------------------------------------

=head2 add_new_user($user_details)

Adds a new user to the database. Requires one argument, a reference to a hash
containing the following keys:

=over 4

=item username

=item displayname

=item email

=item passphrase [optional]

=back

If the key C<passphrase> is present in the hash, its value will be used to
set the passphrase for the user. If there is no supplied passphrase, a
random passphrase will be generated and returned.

=cut

sub add_new_user {
  my ( $self, $fields ) = @_;

  croak 'ERROR: one of the required fields is missing'
    unless ( defined $fields->{username} and
             defined $fields->{displayname} and
             defined $fields->{email} );

  # make sure the email address is at least well-formed
  croak "ERROR: not a valid email address ($fields->{email})"
    unless Email::Valid->address($fields->{email});

  my $column_values = {
    username    => $fields->{username},
    displayname => $fields->{displayname},
    email       => $fields->{email},
  };

  my $generated_passphrase;
  if ( defined $fields->{passphrase} and
       $fields->{passphrase} ne '' ) {
    $column_values->{passphrase} = $fields->{passphrase}
  }
  else {
    # generate a random passphrase and store that
    $generated_passphrase = $self->generate_passphrase;
    $column_values->{passphrase} = $generated_passphrase;
  }

  # TODO maybe implement roles

  my $user = $self->resultset('User')
                  ->find_or_new( $column_values );

  croak 'ERROR: user already exists; use "update_user" to update'
    if $user->in_storage;

  $user->insert;

  return $generated_passphrase;
}

#-------------------------------------------------------------------------------

=head2 update_user($user_details)

Update the details for the specified user. Requires a single argument, a
reference to a hash containg the user details. The hash must contain the
key C<username>, plus one or more other fields to update. An exception is
thrown if the username is not supplied, if there are no fields to update,
or if the user does not exist.

These are the allowed fields:

=over 4

=item username

=item displayname

=item email

=item passphrase

=back

=cut

sub update_user {
  my ( $self, $fields ) = @_;

  croak 'ERROR: must supply a username'
    unless defined $fields->{username};

  # we need something to update...
  croak 'ERROR: must supply fields to update'
    unless scalar( keys %$fields ) > 1;

  my $column_values = {
    username => $fields->{username},
  };

  if ( defined $fields->{email} ) {
    # make sure the email address is at least well-formed
    croak "ERROR: not a valid email address ($fields->{email})"
      unless Email::Valid->address($fields->{email});
    $column_values->{email} = $fields->{email};
  }

  $column_values->{displayname} = $fields->{displayname} if defined $fields->{displayname};
  $column_values->{passphrase}  = $fields->{passphrase}  if defined $fields->{passphrase};

  # TODO maybe implement roles

  my $user = $self->resultset('User')
                  ->find( $column_values->{username} );

  croak "ERROR: user '$fields->{username}' does not exist; use 'add_user' to add"
    unless defined $user;

  $user->update( $column_values );
}

#-------------------------------------------------------------------------------

=head2 set_passphrase($username,$passphrase)

Set the passphrase for the specified user.

=cut

sub set_passphrase {
  my ( $self, $username, $passphrase ) = @_;

  croak 'ERROR: must supply a username and a passphrase'
    unless ( defined $username and defined $passphrase );

  my $user = $self->resultset('User')
                  ->find($username);

  croak "ERROR: user '$username' does not exist; use 'add_user' to add"
    unless defined $user;

  $user->set_passphrase($passphrase);
}

#-------------------------------------------------------------------------------

=head2 reset_passphrase($username)

Resets the password for the specified user. The reset password is automatically
generated and is returned to the caller.

=cut

sub reset_passphrase {
  my ( $self, $username ) = @_;

  croak 'ERROR: must supply a username' unless defined $username;

  my $user = $self->resultset('User')->find($username);

  croak "ERROR: user '$username' does not exist; use 'add_user' to add"
    unless defined $user;

  return $user->reset_passphrase;
}

#-------------------------------------------------------------------------------

=head2 set_api_key($username)

Reset the API key for the specified user. The API key cannot be supplied; it
will be generated automatically and returned to the caller.

=cut

sub reset_api_key {
  my ( $self, $username ) = @_;

  croak 'ERROR: must supply a username' unless defined $username;

  my $user = $self->resultset('User')
                  ->find($username);

  croak "ERROR: user '$username' does not exist; use 'add_user' to add"
    unless defined $user;

  $user->reset_api_key;

  return $user->api_key;
}

#-------------------------------------------------------------------------------

=head2 generate_passphrase($length?)

Generates a random passphrase string. If C<$length> is supplied, the passphrase
will contain C<$length> characters from the set C<[A-NP-Za-z1-9]> i.e. omitting
zero and the capital letter "O", for clarity. If C<$length> is not specified, the
passphrase will contain 8 characters.

=cut

# TODO this should be moved into a base class that everything else inherits from

sub generate_passphrase {
  my ( $self, $length ) = @_;

  $length ||= 8;

  my $generated_passphrase = '';
  $generated_passphrase .= ['1'..'9','A'..'N','P'..'Z','a'..'z']->[rand 52] for 1..$length;

  return $generated_passphrase;
}

#-------------------------------------------------------------------------------

=head1 SEE ALSO

L<Bio::Metadata::Validator>

=head1 CONTACT

path-help@sanger.ac.uk

=cut

__PACKAGE__->meta->make_immutable;

1;
