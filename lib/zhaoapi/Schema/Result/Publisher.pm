use utf8;
package zhaoapi::Schema::Result::Publisher;

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

__PACKAGE__->table("publisher");



__PACKAGE__->add_columns(
  "publisher_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 15 },
  "status",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "exchange",
  { data_type => "decimal", is_nullable => 1, size => [11, 4] },
  "rounding",
  {
    data_type => "varchar",
    default_value => "floor",
    is_nullable => 0,
    size => 5,
  },
  "currency",
  { data_type => "varchar", is_nullable => 1, size => 8 },
  "sdk_title",
  { data_type => "varchar", is_nullable => 1, size => 45 },
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

=item * L</media_id>

=back

=cut

__PACKAGE__->set_primary_key("publisher_id");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2014-10-14 01:15:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:keKP9bJUwQJlGYqGq9zObA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
