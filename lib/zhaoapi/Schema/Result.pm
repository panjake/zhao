package zhaoapi::Schema::Result;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw/InflateColumn::DateTime UUIDColumns/);

sub insert {
  my $self = shift;
  
  my $column = 'create_time';
  if ( $self->has_column( $column ) and not defined $self->get_column( $column ) ) {
    $self->store_column( $column, \'CURRENT_TIMESTAMP' )
  }
  
  $self->next::method(@_);
}

1;
