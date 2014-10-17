#!/usr/bin/perl -w
use strict;


my @scripts = ('/var/www/zhao/bin/forwardd','/var/www/zhao/bin/callback');

foreach(@scripts){
  my $result = `ps aux | grep "$_" | grep -v "grep" | wc -l`;

  if($result != 1){
    my $begin = `perl "$_" start`;
  }
}