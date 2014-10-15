use utf8;
package zhaoapi::Schema::Result::Achieve;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

zhaoapi::Schema::Result::Achieve

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

=head1 TABLE: C<achieve>

=cut

__PACKAGE__->table("achieve");

=head1 ACCESSORS

=head2 achieve_id

  data_type: 'char'
  default_value: (empty string)
  is_nullable: 0
  size: 36

=head2 date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 click_id

  data_type: 'bigint'
  is_nullable: 1

=head2 campaign_id

  data_type: 'integer'
  is_nullable: 0

=head2 user_id

  data_type: 'integer'
  is_nullable: 1

=head2 media_id

  data_type: 'integer'
  is_nullable: 1

=head2 earnings

  data_type: 'decimal'
  default_value: 0.0000
  is_nullable: 0
  size: [9,4]

??

=head2 expenses

  data_type: 'decimal'
  default_value: 0.0000
  is_nullable: 0
  size: [9,4]

??

=head2 user_agent

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 ip

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 15

=head2 is_accepted

  data_type: 'tinyint'
  is_nullable: 1

????

=head2 accepted_time

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

????

=head2 is_forwarded

  data_type: 'tinyint'
  is_nullable: 1

???????

=head2 forwarded_time

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

?????????

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
  "achieve_id",
  { data_type => "char", default_value => "", is_nullable => 0, size => 36 },
  "date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 0 },
  "click_id",
  { data_type => "bigint", is_nullable => 1 },
  "campaign_id",
  { data_type => "integer", is_nullable => 0 },
  "user_id",
  { data_type => "integer", is_nullable => 1 },
  "media_id",
  { data_type => "integer", is_nullable => 1 },
  "earnings",
  {
    data_type => "decimal",
    default_value => "0.0000",
    is_nullable => 0,
    size => [9, 4],
  },
  "expenses",
  {
    data_type => "decimal",
    default_value => "0.0000",
    is_nullable => 0,
    size => [9, 4],
  },
  "user_agent",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "ip",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 15 },
  "is_accepted",
  { data_type => "tinyint", is_nullable => 1 },
  "accepted_time",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "is_forwarded",
  { data_type => "tinyint", is_nullable => 1 },
  "forwarded_time",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "last_update",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "create_time",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => "2010-01-01 00:00:00",
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</achieve_id>

=item * L</date>

=back

=cut

__PACKAGE__->set_primary_key("achieve_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<i_user_campaign>

=over 4

=item * L</user_id>

=item * L</campaign_id>

=back

=cut


__PACKAGE__->add_unique_constraint("i_user_campaign", ["user_id", "campaign_id"]);





__PACKAGE__->belongs_to('campaign' => 'zhaoapi::Schema::Result::Campaign', 'campaign_id');
__PACKAGE__->belongs_to('click' => 'zhaoapi::Schema::Result::Click', 'click_id');
__PACKAGE__->belongs_to('media' => 'zhaoapi::Schema::Result::Media', 'media_id');
__PACKAGE__->belongs_to('user' => 'zhaoapi::Schema::Result::User', 'user_id');
__PACKAGE__->might_have('achieve_to_forward' => 'zhaoapi::Schema::Result::AchieveToForward', 'achieve_id');


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2014-10-14 01:15:13
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QgZyIphSfzpd6NuhLQ9EWQ






# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
