use utf8;
package zhaoapi::Schema::Result::Click;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

zhaoapi::Schema::Result::Click

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

=head1 TABLE: C<click>

=cut

__PACKAGE__->table("click");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 campaign_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 media_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 user_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 identifier

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 identifier2

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 user_agent

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 ip

  data_type: 'varchar'
  is_nullable: 1
  size: 15

=head2 system

  data_type: 'varchar'
  is_nullable: 1
  size: 255

??????

=head2 create_time

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 last_update

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "click_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 0 },
  "campaign_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "media_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "user_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "identifier",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "identifier2",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "user_agent",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "ip",
  { data_type => "varchar", is_nullable => 1, size => 15 },
  "system",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "create_time",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "last_update",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("click_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<u_date_id>

=over 4

=item * L</date>

=item * L</id>

=back

=cut

__PACKAGE__->add_unique_constraint("u_date_id", ["date", "click_id"]);


__PACKAGE__->belongs_to('campaign' => 'zhaoapi::Schema::Result::Campaign', 'campaign_id');
__PACKAGE__->belongs_to('media' => 'zhaoapi::Schema::Result::Media', 'media_id');
__PACKAGE__->belongs_to('user' => 'zhaoapi::Schema::Result::User', 'user_id');
__PACKAGE__->has_many('achieves' => 'zhaoapi::Schema::Result::Achieve', 'click_id');


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2014-10-14 01:15:13
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hTLORaCHkA07+ndbuhIx5A





# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
