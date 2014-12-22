package zhaoapi::Manager;
use Dancer ':syntax';
use strict;
use warnings;
use Dancer::Plugin::DBIC;
use zhaoapi::Schema;
set serializer => 'JSON';

prefix undef;

get '/admin' => sub{
	warn 'test';
};


get '/restart' => sub{
	my $sys = `perl /var/www/zhao/bin/check_forward.pl`;
	
	sleep 2;
	warn $sys;
};

true;