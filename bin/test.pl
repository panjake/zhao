#!/usr/bin/perl


use FindBin qw( $Bin );
use lib "$Bin/../Daemon";
use Moose;
use Path::Class qw( dir file );
use daemon::Click;
use daemon::Achieve;
use daemon::DB;
use Data::Dump qw/dump/;


my $dba = daemon::DB->new();


my $type = $ARGV[0];
unless($type or $type ne 'forward' or $type ne 'callback'){
  die 'argument is wrong';
}

if($type eq 'callback'){
    warn "begin to call";
  my $util = new daemon::Click;
  my $callback_confirm = $util->callback_confirm;
    foreach my $click (  @$callback_confirm ) {
      $util->forward( $click );
    }

}elsif($type eq 'forward'){
    warn "begin to forward";
  my $util = new daemon::Achieve;
    my $achieve_to_forward = $util->achieve_to_forward($dba);
    my $achieve;
    foreach $achieve (  @$achieve_to_forward ) {
      
      $util->forward( $achieve );
    }
}elsif($type eq 'test'){
  my $util = new daemon::Callback;
  $util->test;
}
