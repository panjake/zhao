package daemon::Callback;

use Moose;
use namespace::autoclean;
use Path::Class qw( dir file );
use daemon::Click;
use Data::Dump qw/dump/;
use threads;

with qw( MooseX::Daemonize );

has '+pidbase' => (
  default => sub {
    my $dir = dir( shift->basedir, 'var', 'run' );
    $dir->mkpath unless -e $dir;
    return $dir;
  },
);

has 'is_continuable' => (
  is => 'rw',
  isa => 'Bool',
  default => 1,
);

after start => sub {
  my $self = shift;
  return unless $self->is_daemon;
  
  $SIG{'INT'} = sub { $self->is_continuable(0) };
  
  my $logdir = dir( $self->basedir, 'var', 'log' );;
  $logdir->mkpath unless -e $logdir;
  my $logfile = file( $logdir, $self->progname . '.log' );
  close STDOUT;
  open STDOUT, '>>', $logfile;
  my $errfile = file( $logdir, $self->progname . '.err' );
  close STDERR;
  open STDERR, '>>', $errfile;
  
  my $util = new daemon::Click;
  while ( $self->is_continuable ) {
    my $callback_confirm = $util->callback_confirm;
    
    if( $callback_confirm and scalar @$callback_confirm ){
        my $n = (scalar @$callback_confirm) - 1;
        my @threads = map { threads->create( sub{ $util->forward($callback_confirm->[$_]); sleep 1;}) } (0...$n);
        $_->join for @threads;
    }

  }
  
  $self->shutdown;
};

__PACKAGE__->meta->make_immutable;
1;
