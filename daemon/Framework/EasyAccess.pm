package EasyAccess;
use strict;
use warnings(FATAL=>'all');

#===================================
#===Author  : qian.yu            ===
#===Email   : foolfish@cpan.org  ===
#===MSN     : qian.yu@adways.net ===
#===QQ      : 19937129           ===
#===Homepage: www.lua.cn         ===
#===================================

#===3.1.2(2005-08-04): add test_var
#===3.1.1(2005-06-22): fix bug
#===3.1.0(2005-06-20): fix some bugs
#===3.0.0            : support array handler
#===2.0.0            : rewrite the code ,dont use autoload at all
#===1.0.0            : first release

#the standard format of $path start with / and end without /

my $_pkg_name=__PACKAGE__;
my $_pkg_name_handler='EasyHandler';
sub foo{1};

sub new{
	my ($class,$rh_handlers,$rh_option)=@_;
	my $self=bless {},$_pkg_name;
	$self->{rh_handlers}=$rh_handlers;
	$self->{rh_option}=$rh_option;
	$self->{rh_option}->{self}=$self;
	#===3.1.2
	#store test variable;
	#set it '' initial because of u can print it without warning(print undef will cause a warning)
	$self->{test_var}='';
	return $self;
};

sub func{
	my($self,$path,$func,@param)=@_;
	my $ra_path=[];
	foreach(split(/\//,$path)){
#TODO try to not use regex
#		$dir=~s/^\s+//;
#		$dir=~s/\s+$//;
		if($_ ne ''){push @$ra_path,$_;}
	}

	my $ra_params=[];
	foreach(@param){
		if(ref $_ ne $_pkg_name_handler){
			push @$ra_params,EasyHandler->new($_);
		}else{
			push @$ra_params,$_;
		}
	};

	my $r=fc($self->{rh_handlers},$func,$ra_path,$self->{rh_option},$ra_params);
	if(&Framework::Common::ERR_HANDLER_NOT_FOUND($r)){
		my $caller='';
		for(my $i=0;;$i++){
			my $ra_caller_info=[caller($i)];
			if(scalar(@$ra_caller_info)==0){last;}
			else{
				$caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
			}
		}
		$caller="CallerInfo:\n$caller";
		CORE::die "$_pkg_name: handler not found\n$caller";
	}else{
		return $r;
	}	
}

sub fc{
	my ($handler,$func,$ra_path,$rh_option, $ra_params)=@_;
	my $type=ref $handler;
	if($type eq 'HASH'){
		if(scalar(@$ra_path)>0&&defined($handler->{$ra_path->[0]})){
			return fc($handler->{shift @$ra_path},$func,$ra_path,$rh_option,$ra_params);
		}else{
			return &Framework::Common::ERR_HANDLER_NOT_FOUND();
		}
	}elsif($type eq 'ARRAY'){
		foreach(@$handler){
			my $r=fc($_,$func,$ra_path,$rh_option,$ra_params);
			if(&Framework::Common::ERR_HANDLER_NOT_FOUND($r)){
				next;
			}else{
				return $r;
			}
		}
		#===3.1.1
		return &Framework::Common::ERR_HANDLER_NOT_FOUND();
	}elsif(ref $handler eq $_pkg_name_handler){
		return $handler->execute($func,$ra_path,$rh_option,@$ra_params);
	}else{
		CORE::die $_pkg_name.': handler not found';
		return &Framework::Common::ERR_HANDLER_NOT_FOUND();
	}
}

DESTROY{}
1;
__END__