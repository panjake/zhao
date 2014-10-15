use utf8;
package zhaoapi::Schema::Result::ClickToForward;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

zhaoapi::Schema::Result::ClickToForward

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

=head1 TABLE: C<click_to_forward>

=cut

__PACKAGE__->table("click_to_forward");

=head1 ACCESSORS

=head2 click_id

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

=head2 create_time

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "click_id",
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
  "create_time",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</click_id>

=back

=cut

__PACKAGE__->set_primary_key("click_id");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2014-10-14 01:15:13
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LbOfAlL3sgAShi9ZhPt3qA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
