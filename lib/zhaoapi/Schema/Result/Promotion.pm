use utf8;
package zhaoapi::Schema::Result::Promotion;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

zhaoapi::Schema::Result::Campaign

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

=head1 TABLE: C<campaign>

=cut

__PACKAGE__->table("promotion");



__PACKAGE__->add_columns(
  "promotion_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 15 },
  "location",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "icon",
  { data_type => "varchar", default_value => "", is_nullable => 1, size => 255 },
  "start_time",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    default_value => "2010-01-01 00:00:00",
    is_nullable => 0,
  },
  "end_time",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    default_value => "2110-12-31 23:59:59",
    is_nullable => 0,
  },
  "package_name",
  { data_type => "varchar", default_value => "", is_nullable => 1, size => 45 },
  "conditions",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 45 },
  "icon",
  { data_type => "varchar", default_value => "", is_nullable => 1, size => 255 },

  "status",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "budget",
  {
    data_type => "decimal",
    default_value => "0.0000",
    is_nullable => 0,
    size => [11, 4],
  },
  "spending",
  {
    data_type => "decimal",
    default_value => "0.0000",
    is_nullable => 0,
    size => [11, 4],
  },
  "earnings",
  {
    data_type => "decimal",
    default_value => "0.00",
    is_nullable => 1,
    size => [4, 2],
  },
  "expenses",
  {
    data_type => "decimal",
    default_value => "0.00",
    is_nullable => 1,
    size => [4, 2],
  },
  "key",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "last_update",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
);


__PACKAGE__->set_primary_key("promotion_id");



#__PACKAGE__->has_many( achieves => 'zhaoapi::Schema::Result::Achieve', 'campaign_id' );


=head1 PRIMARY KEY

=over 4

=item * L</campaign_id>

=back

=cut

# use DateTime;

# sub is_available {
#   my $self = shift;
  
#   my $is_available = 0;
#   my $now = DateTime->now( time_zone => 'Asia/Shanghai' );
  
#   $self->start_time le $now
#     && $now le $self->end_time
#     && $self->status == 1
#     && $self->balance > 0
#   and $is_available = 1;
  
#   return $is_available;
# }

# sub balance {
#   my $self = shift;
#   return $self->budget - $self->spending;
# }






# Created by DBIx::Class::Schema::Loader v0.07042 @ 2014-10-14 01:15:13
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8hRNgZseqLQVnDjytGYODA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
