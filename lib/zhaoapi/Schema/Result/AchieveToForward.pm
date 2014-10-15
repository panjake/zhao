use utf8;
package zhaoapi::Schema::Result::AchieveToForward;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

zhaoapi::Schema::Result::AchieveToForward

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<achieve_to_forward>

=cut

__PACKAGE__->table("achieve_to_forward");

=head1 ACCESSORS

=head2 achieve_id

  data_type: 'char'
  is_nullable: 0
  size: 36

=head2 forward_time

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 attempted

  data_type: 'tinyint'
  is_nullable: 1

??????

=head2 message

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=cut

__PACKAGE__->add_columns(
  "achieve_id",
  { data_type => "char", is_nullable => 0, size => 36 },
  "forward_time",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "attempted",
  { data_type => "tinyint", is_nullable => 1 },
  "message",
  { data_type => "varchar", is_nullable => 1, size => 45 },
);

=head1 PRIMARY KEY

=over 4

=item * L</achieve_id>

=back

=cut

__PACKAGE__->set_primary_key("achieve_id");


__PACKAGE__->has_one('achieve' => 'zhaoapi::Schema::Result::Achieve', 'achieve_id', { cascade_delete => 0 });


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2014-10-14 01:15:13
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hsAQ6lvpSW6JBJ+DLzPmMw

use Try::Tiny;

sub forwarded {
  my ( $self, $is_forwarded ) = @_;
  
  my $txn = sub {
    $self->achieve->update({
      is_forwarded => $is_forwarded,
      forwarded_time => \'NOW()',
    });
    $self->delete;
  };
  try {
    $self->result_source->schema->txn_do( $txn );
  }
  catch {
    warn $_;
  }
}


sub defer {
  my ( $self, $message ) = @_;
  
  if ( defined $message ) {
    $self->message( $message );
  }
  
  my $minute = 2 ** $self->attempted;
  $self->update({
    attempted    => \'attempted + 1',
    forward_time => \"DATE_ADD( NOW(), INTERVAL $minute MINUTE )",
  });
}


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
