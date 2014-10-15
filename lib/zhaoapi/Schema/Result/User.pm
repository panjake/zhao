use utf8;
package zhaoapi::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

zhaoapi::Schema::Result::User - ??

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

=head1 TABLE: C<user>

=cut

__PACKAGE__->table("user");

=head1 ACCESSORS

=head2 user_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 model

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 45

??

=head2 identifier

  data_type: 'char'
  is_nullable: 1
  size: 64

openudid

=head2 identifier2

  data_type: 'char'
  is_nullable: 1
  size: 64

mac address

=head2 last_update

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 create_time

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: '2010-01-01 00:00:00'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "user_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "identifier",
  { data_type => "char", is_nullable => 1, size => 64 },
  "identifier2",
  { data_type => "char", is_nullable => 1, size => 64 },
  "last_update",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</user_id>

=back

=cut

__PACKAGE__->set_primary_key("user_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<u_identifier>

=over 4

=item * L</identifier>

=back

=cut

__PACKAGE__->add_unique_constraint("u_identifier", ["identifier"]);

__PACKAGE__->has_many( clicks => 'zhaoapi::Schema::Result::Click', 'user_id' );
__PACKAGE__->has_many( achieves => 'zhaoapi::Schema::Result::Achieve', 'user_id' );

# Created by DBIx::Class::Schema::Loader v0.07042 @ 2014-10-14 01:15:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:tG2sEoTAHKI5MTEJQXwwcQ


sub click_of_campaign {
  my ( $self, $campaign ) = @_;
  
  my $click = $self->search_related('clicks',
    {
      campaign_id => $campaign->id,
    },
    {
      order_by => 'me.date DESC, me.click_id DESC',
      page     => 1,
      rows     => 1,
    },
  )->first;
  
  return $click;
}


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
