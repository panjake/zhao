package zhaoapi::Schema::Result::ReportOfAction;


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



__PACKAGE__->table("report_of_action");
__PACKAGE__->add_columns(
  "report_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "date",
  { data_type => "date", is_nullable => 0 },
  "publisher_id",
  { data_type => "integer", is_nullable => 0 },
  "promotion_id",
  { data_type => "integer", is_nullable => 0 },
  "view",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "click",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "achieve",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "earnings",
  {
    data_type => "decimal",
    default_value => "0.0000",
    is_nullable => 0,
    size => [13, 4],
  },
  "expenses",
  {
    data_type => "decimal",
    default_value => "0.0000",
    is_nullable => 0,
    size => [13, 4],
  },
  "last_update",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
  },
);
__PACKAGE__->set_primary_key("report_id");
__PACKAGE__->add_unique_constraint("u_date_media_campaign", ["date", "publisher_id", "promotion_id"]);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-04-18 17:04:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fWMUpFVGmSnjW0BrKBPVGg


__PACKAGE__->belongs_to( 'promotion' => 'zhaoapi::Schema::Result::Promotion', 'promotion_id' );

1;


# You can replace this text with custom content, and it will be preserved on regeneration
1;
