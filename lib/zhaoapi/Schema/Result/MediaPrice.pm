use utf8;
package zhaoapi::Schema::Result::MediaPrice;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

zhaoapi::Schema::Result::MediaPrice

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

=head1 TABLE: C<media_price>

=cut

__PACKAGE__->table("media_price");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 campaign_id

  data_type: 'integer'
  is_nullable: 0

=head2 price_b

  data_type: 'decimal'
  default_value: 0.00
  is_nullable: 1
  size: [4,2]

=head2 media_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "campaign_id",
  { data_type => "integer", is_nullable => 0 },
  "price_b",
  {
    data_type => "decimal",
    default_value => "0.00",
    is_nullable => 1,
    size => [4, 2],
  },
  "media_id",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<u_campaign_meida>

=over 4

=item * L</campaign_id>

=item * L</media_id>

=back

=cut

__PACKAGE__->add_unique_constraint("u_campaign_meida", ["campaign_id", "media_id"]);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2014-10-14 01:15:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:m5/QvV5TKBiDdZEgJ4f2Sw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
