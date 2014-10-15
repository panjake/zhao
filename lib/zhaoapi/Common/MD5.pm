package zhaoapi::Common::MD5;
use Moose;
use namespace::autoclean;

use Digest::MD5 qw/md5_hex/;

has 'key' => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);

sub md5digest {
  my ( $self, $param ) = @_;
  
  exists $param->{ sign } and delete $param->{ sign };
  
  my $str =  join ',', map( { $param->{ $_ } } sort keys %$param );
  $str .= ",".$self->key;
  return md5_hex($str);
}

__PACKAGE__->meta->make_immutable;
