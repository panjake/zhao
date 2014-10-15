use utf8;
package zhaoapi::Schema::Result::Media;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

zhaoapi::Schema::Result::Media

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

=head1 TABLE: C<media>

=cut

__PACKAGE__->table("media");

=head1 ACCESSORS

=head2 media_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 is_approved

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

??rank 

=head2 callback

  data_type: 'varchar'
  is_nullable: 1
  size: 255

????URL

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
  "media_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "is_approved",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "callback",
  { data_type => "varchar", is_nullable => 1, size => 255 },
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

=item * L</media_id>

=back

=cut

__PACKAGE__->set_primary_key("media_id");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2014-10-14 01:15:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:keKP9bJUwQJlGYqGq9zObA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
