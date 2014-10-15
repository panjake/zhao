package EasyTool;
use strict;
use warnings(FATAL=>'all');
use Time::Local;
use FileHandle;

sub foo{1};
sub _name_pkg_name{__PACKAGE__;}

#===========================================
#===ture and false
	sub _name_true{1;}
	sub _name_false{'';}
	sub true{scalar(@_)==1?defined($_[0])&&($_[0] eq &_name_true):&_name_true;}
	sub false{scalar(@_)==1?defined($_[0])&&($_[0] eq &_name_false):&_name_false;}
#===========================================

#===========================================
#====regional and language
	sub _name_un{'un';} #Country Independent
	sub _name_cn{'cn';} #China
	sub _name_jp{'jp';} #Japan
#===========================================

#===========================================
#===names for encoding
	#===un
	sub _name_utf8{'utf8';}
	#===cn
	sub _name_gb2312{'gb2312';}
	sub _name_gbk{'gbk';}
	sub _name_gb18030{'gb18030';}
	#===jp
	sub _name_euc_jp{'euc-jp';}
	sub _name_shift_jis{'shift-jis';}
	sub _name_iso_2022_jp{'iso-2022-jp';}
#===========================================

#===========================================
#===datetime
	#===un
	sub _name_datetime_zero_gmt{946684800;}
	#===cn
	sub _name_timezone_china{8;}
	sub _name_datetime_zero_china{946656000;}
	#===jp
	sub _name_timezone_japan{9;}
	sub _name_datetime_zero_japan{946652400;}
#===========================================

#===========================================
#===Common Define
#$flag:	_name_true for true and _name_false for false
#$str : a scalar can be a string or undef
#===========================================

#===$flag=is_int($str,$min,$max);
#===check whether $str is integer and  $max>$str>=$min
#===$flag=is_int($str);
#===check whether $str is integer and  2147483648>$str>=-2147483648
#===$min :  set null if no lower bound restrict
#===$max :  set null if no upper bound restrict
sub is_int{
	my $param_count=scalar(@_);
	my ($str,$num,$max,$min)=(exists $_[0]?$_[0]:$_,undef,undef,undef);
	if($param_count==1||$param_count==2||$param_count==3){
		eval{$num=int($str);};
		if($@){undef $@;return defined(&_name_false)?&_name_false:'';}
		if($num ne $str){return defined(&_name_false)?&_name_false:'';}
		if($param_count==1){
			$max=2147483648;$min=-2147483648;
		}elsif($param_count==2){
			$max=2147483648;$min=$_[1];
		}elsif($param_count==3){
			$max=$_[2];$min=$_[1];
		}else{
			CORE::die 'is_int: BUG!';
		}
		if((!defined($min)||$num>=$min)&&(!defined($max)||$num<$max)){
			return defined(&_name_true)?&_name_true:1;
		}else{
			return defined(&_name_false)?&_name_false:'';
		}
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'is_int: param count should be 1, 2 or 3');
	}
}

#===$flag=is_id($id)
#===check 32bit unsigned int id,start from 1
sub is_id{
	return is_int(shift,1,4294967296);
}

#===$flag=is_email($id)
#===check whether a valid email address
sub is_email{
	my $param_count=scalar(@_);
	if($param_count==1){
		local $_=$_[0];
		if(!defined($_)){
			return defined(&_name_false)?&_name_false:'';
		}elsif(/^[a-zA-Z0-9\_]\@([a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,6}$/){
			return defined(&_name_true)?&_name_true:1;
		}elsif(/^[a-zA-Z0-9\_][a-zA-Z0-9\_\.\-]*[a-zA-Z0-9\_]\@([a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,6}$/){
			return defined(&_name_true)?&_name_true:1;
		}else{
			return defined(&_name_false)?&_name_false:'';
		}
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'is_email: param count should be 1');
	}
}


#===$str=trim($str)
#===delete blank before and after $str, return undef if $str is undef
sub trim {
	my $param_count=scalar(@_);
	if($param_count==1){
		local $_=$_[0];
		unless(defined($_)){return undef;}
		s/^\s+//,s/\s+$//;
		return $_ ;
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'trim: param count should be 1');
	}
}

#===$flag=in($word,$word1,$word2,..)
#===if $word in $word1,$word2... return true else return false
#===$flag=in($word,$rh)
#===if $word in keys of $rh return true else return false
#===$word can be undef
sub in {
	my $param_count=scalar(@_);
	if(($param_count==2)&&(ref ($_[1]) eq 'HASH')){
		if(defined($_[0])){
			if(exists $_[1]->{$_[0]}){
				return defined(&_name_true)?&_name_true:1;
			}else{
				return defined(&_name_false)?&_name_false:'';
			}
		}else{
			return defined(&_name_false)?&_name_false:'';
		}
	}elsif($param_count>=1){
		my $word=shift;
		foreach(@_){
			if(defined($word)&&defined($_)&&($word eq $_)){
				return defined(&_name_true)?&_name_true:1;
			}elsif((!defined($word))&&(!defined($_))){
				return defined(&_name_true)?&_name_true:1;	
			}else{
				next;
			}
		}
		return defined(&_name_false)?&_name_false:'';
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'in: param count should be at least 1');
	}
}

#===$flag=ifnull($scalar1,$scalar2)
#===If $scalar1 is not undef, return $scalar1, else return $scalar2
sub ifnull{
	my $param_count=scalar(@_);
	if($param_count==2){
		return defined($_[0])?$_[0]:$_[1];
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'ifnull: param count should be 2');
	}
}

#===$bytes=read_file($file_path)
sub read_file{
	my $file_path=shift;
	my $_max_file_len = 100000000;
	my $fh=FileHandle->new($file_path,'r');
	if(!defined($fh)){
		CORE::die defined(&_name_pkg_name)?&_name_pkg_name.'::':''.'read_file: open file failed';#return undef
	}
	binmode($fh);
	my $bytes;
	$fh->read($bytes,$_max_file_len);
	$fh->close();
	$bytes;
}

#===$byte_count=write_file($file_path,$bytes)
sub write_file{
	my ($file_path,$bytes)=@_;
	my $fh=FileHandle->new($file_path,'w');
	if(!defined($fh)){
		CORE::die defined(&_name_pkg_name)?&_name_pkg_name.'::':''.'write_file: open file failed';#return undef
	}
	binmode($fh);
	my $byte_count=$fh->syswrite($bytes);
	$fh->close();
	return $byte_count;
}

#===$byte_count=append_file($file_path,$bytes)
sub append_file{
	my ($file_path,$bytes)=@_;
	my $fh=FileHandle->new($file_path,'a');
	if(!defined($fh)){
		CORE::die defined(&_name_pkg_name)?&_name_pkg_name.'::':''.'append_file: open file failed';#return undef
	}
	binmode($fh);
	my $byte_count=$fh->syswrite($bytes);
	$fh->close();
	return $byte_count;
}

sub qquote {
	local($_) = shift;
	s/([\\\"\@\$])/\\$1/g;
	s/([^\x00-\x7f])/sprintf("\\x{%04X}",ord($1))/eg if utf8::is_utf8($_);
	return qq("$_") unless 
		/[^ !"\#\$%&'()*+,\-.\/0-9:;<=>?\@A-Z[\\\]^_`a-z{|}~]/;  # fast exit
	s/([\a\b\t\n\f\r\e])/{
		"\a" => "\\a","\b" => "\\b","\t" => "\\t","\n" => "\\n",
    	"\f" => "\\f","\r" => "\\r","\e" => "\\e"}->{$1}/eg;
	s/([\0-\037\177])/'\\x'.sprintf('%02X',ord($1))/eg;
	s/([\200-\377])/'\\x'.sprintf('%02X',ord($1))/eg;
	return qq("$_");
}

sub qquote_bin{
	local($_) = shift;
	s/([\x00-\xff])/'\\x'.sprintf('%02X',ord($1))/eg;
	s/([^\x00-\x7f])/sprintf("\\x{%04X}",ord($1))/eg if utf8::is_utf8($_);
	return qq("$_");
}

sub dump{
	my $max_line=80;
	my $param_count=scalar(@_);
	my ($flag,$str1,$str2);
	if($param_count==1){
		my $data=$_[0];
		my $type=ref $data;
		if($type eq 'ARRAY'){
			my $strs=[];
			foreach(@$data){push @$strs,&dump($_);}

			$str1='[';$flag=0;
			foreach(@$strs){$str1.=$_.",\x20";$flag=1;}
			if($flag==1){chop($str1);chop($str1);}
			$str1.=']';

			$str2='[';
			foreach(@$strs){s/\n/\n\x20\x20/g;$str2.="\n\x20\x20".$_.',';}
			$str2.="\n]";

			return length($str1)>$max_line?$str2:$str1;
		}elsif($type eq 'HASH'){
			my $strs=[];
			foreach(keys(%$data)){push @$strs,[qquote($_),&dump($data->{$_})];}

			$str1='{';$flag=0;
			foreach(@$strs){$str1.="$_->[0]\x20=>\x20$_->[1],\x20";$flag=1;}
			if($flag==1){chop($str1);chop($str1);}
			$str1.='}';

			$str2='{';
			foreach(@$strs){ $_->[1]=~s/\n/\n\x20\x20/g;$str2.="\n\x20\x20$_->[0]\x20=>\x20$_->[1],";}
			$str2.="\n}";

			return length($str1)>$max_line?$str2:$str1;
		}elsif($type eq 'SCALAR'||$type eq 'REF'){
			return "\\".&dump($$data);
		}elsif($type eq ''){
			$flag=0;
			if(!defined($data)){return 'undef'};
			eval{if($data eq int $data){$flag=1;}};
			if($@){undef $@;}
			if($flag==0){return qquote($data);}
			elsif($flag==1){return $data;}
			else{ die 'dump:BUG!';}
		}else{
			return ''.$data;#===if not a simple type
		}
	}else{
		my $strs=[];
		foreach(@_){push @$strs,&dump($_);}

		$str1='(';
		$flag=0;
		foreach(@$strs){$str1.=$_.",\x20";$flag=1;}
		if($flag==1){chop($str1);chop($str1);}
		$str1.=')';

		$str2='(';
		foreach(@$strs){s/\n/\n\x20\x20/g;$str2.="\n\x20\x20".$_.',';}
		$str2.="\n)";

		return length($str1)>$max_line?$str2:$str1;
	}
}

my $var=undef;
sub test_var{
	our $var;
	if(scalar(@_)==1){
		$var=$_[0];
	}else{
		return $var;
	}
}

#===time support function
#===support year from 2000 to 2037
#===if you want more function,please use EasyDateTime
#===the time zone used in these function is server local time zone

#===To use these function please 
#require Time::Local;

#===the 'time' in function name means time_str, please read the description of $time_str

#===$timestamp : unix timestamp, an integer like 946656000
#===$datetime  : date time string, a string, like '2004-08-28 08:06:00'
#===$date      : date string, a string like, like '2004-08-28'

#===$rh_offset : a hash represent the offset in two times
#===$rh_offset is a struct like {year=>0,month=>0,day=>0,hour=>0,min=>0,sec=>0}
#===if some item in $rh_offset is not set ,use zero instead, integer can be negative
#===one month: {month=>1} 
#===one day  : {day=>1}

#===$time_str
#Samples can be accepted
#	'2004-08-28 08:06:00' ' 2004-08-28 08:06:00 '
#	'2004-08-28T08:06:00' '2004/08/28 08:06:00'
#	'2004.08.28 08:06:00' '2004-08-28 08.06.00'
#	'04-8-28 8:6:0' '2004-08-28' '08:06:00'
#	'946656000'
#Which string can be accepted?
#	rule 0:an int represent seconds since the Unix Epoch (January 1 1970 00:00:00 GMT) can be accepted
#	rule 1:there can be some blank in the begin or end of DATETIME_STR e.g. ' 2004-08-28 08:06:00 '
#	rule 2:date can be separate by . / or - e.g. '2004/08/28 08:06:00'
#	rule 3:time can be separate by . or : e.g. '2004-08-28 08.06.00'
#	rule 4:date and time can be join by white space or 'T' e.g. '2004-08-28T08:06:00'
#	rule 5:can be (date and time) or (only date) or (only time) e.g. '2004-08-28' or '08:06:00'
#	rule 6:year can be 2 digits or 4 digits,other field can be 2 digits or 1 digit e.g. '04-8-28 8:6:0'
#	rule 7:if only the date be set then the time will be set to 00:00:00
#		if only the time be set then the date will be set to 2000-01-01

#===$template option
#===FORMAT
#%datetime   return string like '2004-08-28 08:06:00'
#%date       return string like '2004-08-28'
#%timestamp  return unix timestamp

#===YEAR
#%yyyy       A full numeric representation of a year, 4 digits(2004)
#%yy         A two digit representation of a year(04)

#===MONTH
#%MM         Numeric representation of a month, with leading zeros (01..12)
#%M          Numeric representation of a month, without leading zeros (1..12)

#===DAY
#%dd         Day of the month, 2 digits with leading zeros (01..31)
#%d          Day of the month without leading zeros (1..31)

#===HOUR
#%h12        12-hour format of an hour without leading zeros (1..12)
#%h          24-hour format of an hour without leading zeros (0..23)
#%hh12       12-hour format of an hour with leading zeros (01..12)
#%hh         24-hour format of an hour with leading zeros (00..23)
#%ap         a Lowercase Ante meridiem and Post meridiem  (am or pm)
#%AP         Uppercase Ante meridiem and Post meridiem (AM or PM)

#===MINUTE
#%mm         Minutes with leading zeros (00..59)
#%m          Minutes without leading zeros (0..59)

#===SECOND
#%ss         Seconds, with leading zeros (00..59)
#%s          Seconds, without leading zeros (0..59)

##########################################################################

#===for internal use
sub _time_func_is_int{
	my $param_count=scalar(@_);
	my ($str,$num,$max,$min)=(exists $_[0]?$_[0]:$_,undef,undef,undef);
	if($param_count==1||$param_count==2||$param_count==3){
		eval{$num=int($str);};
		if($@){undef $@;return defined(&_name_false)?&_name_false:'';}
		if($num ne $str){return defined(&_name_false)?&_name_false:'';}
		if($param_count==1){
			$max=2147483648;$min=-2147483648;
		}elsif($param_count==2){
			$max=2147483648;$min=$_[1];
		}elsif($param_count==3){
			$max=$_[2];$min=$_[1];
		}else{
			CORE::die '_time_func_is_int: BUG!';
		}
		if((!defined($min)||$num>=$min)&&(!defined($max)||$num<$max)){
			return defined(&_name_true)?&_name_true:1;
		}else{
			return defined(&_name_false)?&_name_false:'';
		}
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'_time_func_is_int: param count should be 1, 2 or 3');
	}
}



#===$format_str=time_2_str($time_str[,$template])
#===time_2_str($time_str) return str sush as '2000-01-01 00:00:00'
#===time_2_str($time_str,'%yyyy-%MM-%dd') return str sush as '2000-01-01'
sub time_2_str {
	my $param_count=scalar(@_);
	if($param_count==1){
		unless($_[0]){return undef;}
		local $_=time_2_timestamp($_[0]);
		$_=[localtime($_)];
		return sprintf('%04s-%02s-%02s %02s:%02s:%02s',$_->[5]+1900,$_->[4]+1,$_->[3],$_->[2],$_->[1],$_->[0]);
	}elsif($param_count==2){
		unless($_[0]){return undef;}
		local $_=time_2_timestamp($_[0]);
		my $format_str=$_[1];
		if(!defined($format_str)){
			$_=[localtime($_)];
			return sprintf('%04s-%02s-%02s %02s:%02s:%02s',$_->[5]+1900,$_->[4]+1,$_->[3],$_->[2],$_->[1],$_->[0]);
		}
		my $t=[localtime($_)];

		my $map={
			ss=>sprintf('%02s',$t->[0]),
			s=>$t->[0],
			mm=>sprintf('%02s',$t->[1]),
			m=>$t->[1],
			AP=>$t->[2]>12||$t->[2]==0?'PM':'AM',
			ap=>$t->[2]>12||$t->[2]==0?'pm':'am',
			hh=>sprintf('%02s',$t->[2]),
			h=>$t->[2],
			hh12=>sprintf('%02s',$t->[2]?($t->[2]>12?($t->[2]-12):$t->[2]):12),
			h12=>$t->[2]?($t->[2]>12?($t->[2]-12):$t->[2]):12,
			dd=>sprintf('%02s',$t->[3]),
			d=>$t->[3],
			MM=>sprintf('%02s',$t->[4]+1),
			M=>$t->[4]+1,
			yyyy=>$t->[5]+1900,
			yy=>($t->[5]+1900)%100,
			date=>sprintf('%04s-%02s-%02s',$t->[5]+1900,$t->[4]+1,$t->[3]),
			datetime=>sprintf('%04s-%02s-%02s %02s:%02s:%02s',$t->[5]+1900,$t->[4]+1,$t->[3],$t->[2],$t->[1],$t->[0]),
			timestamp=>$_
		};

		$format_str=~s/%timestamp/$map->{timestamp}/g;
		$format_str=~s/%datetime/$map->{datetime}/g;
		$format_str=~s/%date/$map->{date}/g;
		$format_str=~s/%yyyy/$map->{yyyy}/g;
		$format_str=~s/%hh12/$map->{hh12}/g;
		$format_str=~s/%h12/$map->{h12}/g;
		$format_str=~s/%ss/$map->{ss}/g;
		$format_str=~s/%mm/$map->{mm}/g;
		$format_str=~s/%AP/$map->{AP}/g;
		$format_str=~s/%ap/$map->{ap}/g;
		$format_str=~s/%hh/$map->{hh}/g;
		$format_str=~s/%dd/$map->{dd}/g;
		$format_str=~s/%MM/$map->{MM}/g;
		$format_str=~s/%yy/$map->{yy}/g;
		$format_str=~s/%h/$map->{h}/g;
		$format_str=~s/%M/$map->{M}/g;
		$format_str=~s/%d/$map->{d}/g;
		$format_str=~s/%m/$map->{m}/g;
		$format_str=~s/%s/$map->{s}/g;

		return $format_str;
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'time_2_str: param count should be 1 or 2');
	}
}

#===$timestamp=time_2_timestamp($time_str)
#2000-01-01 00:00:00 +08:00   946656000
sub time_2_timestamp{
	my $param_count=scalar(@_);
	if($param_count==1){
		local $_ = shift;
		if(!defined($_)) {return undef;}
		if(/^\s*(\d{4}|\d{2})([\-\.\/])(\d{1,2})\2(\d{1,2})\s*$/){
			eval{$_=Time::Local::timelocal(0,0,0,$4,$3-1,$1);};
			if($@){}else{return $_;}
		}elsif(/^\s*(\d{4}|\d{2})([\-\.\/])(\d{1,2})\2(\d{1,2})(\x20+|T)(\d{1,2})([\:\.])(\d{1,2})\7(\d{1,2})\s*$/){
			eval{$_=Time::Local::timelocal($9,$8,$6,$4,$3-1,$1);};
			if($@){}else{return $_;}
		}elsif(/^\s*(\d{1,2})([\:\.])(\d{1,2})\2(\d{1,2})\s*$/){
			eval{$_=Time::Local::timelocal($4,$3,$1,1,1-1,2000);};
			if($@){}else{return $_;}
		}elsif(&_time_func_is_int($_,946641600,2145916800)){
			return $_;
		}else{
			
		}
	}else{
		
	}
	return 0;
}

#===$flag=is_time($time_str)
sub is_time{
	my $param_count=scalar(@_);
	if($param_count==1){
		my $true =defined(&_name_true)?&_name_true:1;
		my $false=defined(&_name_false)?&_name_false:'';
		local $_ = $_[0];
		if(!defined($_)){return $false;}#if undef
		if(ref $_ ne ''){return $false;}#if not a scalar
		if(/^\s*(\d{4}|\d{2})([\-\.\/])(\d{1,2})\2(\d{1,2})\s*$/){
			eval{$_=Time::Local::timelocal(0,0,0,$4,$3-1,$1);};
			if($@){undef $@;return $false;}else{return $true;}
		}elsif(/^\s*(\d{4}|\d{2})([\-\.\/])(\d{1,2})\2(\d{1,2})(\x20+|T)(\d{1,2})([\:\.])(\d{1,2})\7(\d{1,2})\s*$/){
			eval{$_=Time::Local::timelocal($9,$8,$6,$4,$3-1,$1);};
			if($@){undef $@;return $false;}else{return $true;}
		}elsif(/^\s*(\d{1,2})([\:\.])(\d{1,2})\2(\d{1,2})\s*$/){
			eval{$_=Time::Local::timelocal($4,$3,$1,1,1-1,2000);};
			if($@){undef $@;return $false;}else{return $true;}
		}elsif(&_time_func_is_int($_,946641600,2145916800)){
			return $true;
		}else{
			return $false;
		}
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'is_time: param count should be 1');
	}
}

#===$time=hash_2_time({year=>2000,month=>1,day=>1,hour=>0,min=>0,sec=>0})
#===if some item not set ,default value will be used
sub hash_2_timestamp{
	my $param_count=scalar(@_);
	if($param_count==1){
		local $_ = [];
		my $rh_time=$_[0];
		if(!defined($rh_time)){return undef;}
		$_->[5]=_time_func_is_int($rh_time->{'year'})?$_[0]->{'year'}:2000;
		$_->[4]=_time_func_is_int($rh_time->{'month'})?$_[0]->{'month'}:1;
		$_->[3]=_time_func_is_int($rh_time->{'day'})?$_[0]->{'day'}:1;
		$_->[2]=_time_func_is_int($rh_time->{'hour'})?$_[0]->{'hour'}:0;
		$_->[1]=_time_func_is_int($rh_time->{'min'})?$_[0]->{'min'}:0;
		$_->[0]=_time_func_is_int($rh_time->{'sec'})?$_[0]->{'sec'}:0;
		eval{$_=Time::Local::timelocal($_->[0],$_->[1],$_->[2],$_->[3],$_->[4]-1,$_->[5]);};
		if($@){CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'hash_2_timestamp: not a valid time');}
		return $_;
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'hash_2_timestamp: param count should be 1');
	}
}

#===$rh_time=time_2_hash($time_str)
#===$rh_time is a struct like {year=>2000,month=>1,day=>1,hour=>0,min=>0,sec=>0}
sub time_2_hash{
	my $param_count=scalar(@_);
	if($param_count==1){
		if(!defined($_[0])){return undef;}
		local $_=[localtime(time_2_timestamp($_[0]))];
		return {year=>$_->[5]+1900,month=>$_->[4]+1,day=>$_->[3],hour=>$_->[2],min=>$_->[1],sec=>$_->[0]};
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'time_2_hash: param count should be 1');
	}
}

#===$timestamp=&now();
#===same as CORE::time();
sub now{
	CORE::time();
}

#===$timestamp=&time();
#===same as CORE::time();
sub time{
	CORE::time();
}

#===$date=&date_now();
sub date_now{
	local $_=[localtime(&now())];
	sprintf('%04s-%02s-%02s',$_->[5]+1900,$_->[4]+1,$_->[3]);
}

#===$datetime=&datetime_now();
sub datetime_now{
	local $_=[localtime(&now())];
	sprintf('%04s-%02s-%02s %02s:%02s:%02s',$_->[5]+1900,$_->[4]+1,$_->[3],$_->[2],$_->[1],$_->[0]);
}

#===$timestamp=&timestamp_now();
#===same as now();
sub timestamp_now{
	&now();
}

#===$day_count=day_of_month($year,$month)
sub day_of_month{
	my $param_count=scalar(@_);
	if($param_count==2){
		if(!&_time_func_is_int($_[0],1900,2038)){
			CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'day_of_month: $1 should be integer in [1990,2037]');
		}
		if(!&_time_func_is_int($_[1],1,13)){
			CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'day_of_month: $2 should be integer in [1,12]');
		}
		local $_=[31,28,31,30,31,30,31,31,30,31,30,31]->[$_[1]-1];
		++$_ if $_[1] == 2 && (!($_[0] % 4));
		return $_;
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'day_of_month: param count should be 2');
	}
}

#===$timestamp=timestamp_add($time_str,$rh_offset)
sub timestamp_add{
	my $param_count=scalar(@_);
	if($param_count==2){
		my ($month,$sec)=(0,0);
		if(!is_time($_[0])){
			CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'day_of_month: $1 not a valid time_str');
		}
		if(ref $_[1] ne 'HASH'){
			CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'day_of_month: $2 should be a hash_ref');
		}
		$month+=12*(_time_func_is_int($_[1]->{'year'})?$_[1]->{'year'}:0);
		$month+=_time_func_is_int($_[1]->{'month'})?$_[1]->{'month'}:0;
		$sec+=86400*(_time_func_is_int($_[1]->{'day'})?$_[1]->{'day'}:0);
		$sec+=3600*(_time_func_is_int($_[1]->{'hour'})?$_[1]->{'hour'}:0);
		$sec+=60*(_time_func_is_int($_[1]->{'min'})?$_[1]->{'min'}:0);
		$sec+=_time_func_is_int($_[1]->{'sec'})?$_[1]->{'sec'}:0;
		my $t=[localtime(time_2_timestamp($_[0])+$sec)];
		$t->[5]=int($t->[5]+($t->[4]+$month)/12);
		$t->[4]= ($t->[4]+$month)%12;
		return Time::Local::timelocal($t->[0],$t->[1],$t->[2],$t->[3],$t->[4],$t->[5]);
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'timestamp_add: param count should be 2');
	}
}


#===$timestamp=timestamp_set($time_str,$rh_time)
sub timestamp_set{
	my $param_count=scalar(@_);
	if($param_count==2){
		my $t=[localtime(time_2_timestamp($_[0]))];
		my $rh_time=$_[1];
		$t->[5]=_time_func_is_int($rh_time->{'year'})?$rh_time->{'year'}:$t->[5]+1900;
		$t->[4]=_time_func_is_int($rh_time->{'month'})?$rh_time->{'month'}:$t->[4]+1;
		$t->[3]=_time_func_is_int($rh_time->{'day'})?$rh_time->{'day'}:$t->[3];
		$t->[2]=_time_func_is_int($rh_time->{'hour'})?$rh_time->{'hour'}:$t->[2];
		$t->[1]=_time_func_is_int($rh_time->{'min'})?$rh_time->{'min'}:$t->[1];
		$t->[0]=_time_func_is_int($rh_time->{'sec'})?$rh_time->{'sec'}:$t->[0];
		return Time::Local::timelocal($t->[0],$t->[1],$t->[2],$t->[3],$t->[4]-1,$t->[5]);
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'timestamp_set: param count should be 2');
	}
}

#===$timestamp=date_add($time_str,$rh_offset)
sub date_add{
	my $param_count=scalar(@_);
	if($param_count==2){
		my ($month,$sec)=(0,0);
		if(!is_time($_[0])){
			CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'date_add: $1 not a valid time_str');
		}
		if(ref $_[1] ne 'HASH'){
			CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'date_add: $2 should be a hash_ref');
		}
		$month+=12*(_time_func_is_int($_[1]->{'year'})?$_[1]->{'year'}:0);
		$month+=_time_func_is_int($_[1]->{'month'})?$_[1]->{'month'}:0;
		$sec+=86400*(_time_func_is_int($_[1]->{'day'})?$_[1]->{'day'}:0);
		$sec+=3600*(_time_func_is_int($_[1]->{'hour'})?$_[1]->{'hour'}:0);
		$sec+=60*(_time_func_is_int($_[1]->{'min'})?$_[1]->{'min'}:0);
		$sec+=_time_func_is_int($_[1]->{'sec'})?$_[1]->{'sec'}:0;
		my $t=[localtime(time_2_timestamp($_[0])+$sec)];
		$t->[5]=int($t->[5]+($t->[4]+$month)/12);
		$t->[4]= ($t->[4]+$month)%12;
		return sprintf('%04s-%02s-%02s',$t->[5]+1900,$t->[4]+1,$t->[3]);
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'date_add: param count should be 2');
	}
}

#===$date=date_set($time_str,$rh_time)
sub date_set{
	my $param_count=scalar(@_);
	if($param_count==2){
		my $t=[localtime(time_2_timestamp($_[0]))];
		my $rh_time=$_[1];
		$t->[5]=_time_func_is_int($rh_time->{'year'})?$rh_time->{'year'}:$t->[5]+1900;
		$t->[4]=_time_func_is_int($rh_time->{'month'})?$rh_time->{'month'}:$t->[4]+1;
		$t->[3]=_time_func_is_int($rh_time->{'day'})?$rh_time->{'day'}:$t->[3];
		$t->[2]=_time_func_is_int($rh_time->{'hour'})?$rh_time->{'hour'}:$t->[2];
		$t->[1]=_time_func_is_int($rh_time->{'min'})?$rh_time->{'min'}:$t->[1];
		$t->[0]=_time_func_is_int($rh_time->{'sec'})?$rh_time->{'sec'}:$t->[0];
#TODO if new time is not valid
		return sprintf('%04s-%02s-%02s',$t->[5],$t->[4],$t->[3]);
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'date_set: param count should be 2');
	}
}

#===$timestamp=datetime_add($time_str,$rh_offset)
sub datetime_add{
	my $param_count=scalar(@_);
	if($param_count==2){
		my ($month,$sec)=(0,0);
		if(!is_time($_[0])){
			CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'datetime_add: $1 not a valid time_str');
		}
		if(ref $_[1] ne 'HASH'){
			CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'datetime_add: $2 should be a hash_ref');
		}
		$month+=12*(_time_func_is_int($_[1]->{'year'})?$_[1]->{'year'}:0);
		$month+=_time_func_is_int($_[1]->{'month'})?$_[1]->{'month'}:0;
		$sec+=86400*(_time_func_is_int($_[1]->{'day'})?$_[1]->{'day'}:0);
		$sec+=3600*(_time_func_is_int($_[1]->{'hour'})?$_[1]->{'hour'}:0);
		$sec+=60*(_time_func_is_int($_[1]->{'min'})?$_[1]->{'min'}:0);
		$sec+=_time_func_is_int($_[1]->{'sec'})?$_[1]->{'sec'}:0;
		my $t=[localtime(time_2_timestamp($_[0])+$sec)];
		$t->[5]=int($t->[5]+($t->[4]+$month)/12);
		$t->[4]= ($t->[4]+$month)%12;
		return sprintf('%04s-%02s-%02s %02s:%02s:%02s',$t->[5]+1900,$t->[4]+1,$t->[3],$t->[2],$t->[1],$t->[0]);
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'datetime_add: param count should be 2');
	}
}

#===$date=date_set($time_str,$rh_time)
sub datetime_set{
	my $param_count=scalar(@_);
	if($param_count==2){
		my $t=[localtime(time_2_timestamp($_[0]))];
		my $rh_time=$_[1];
		$t->[5]=_time_func_is_int($rh_time->{'year'})?$rh_time->{'year'}:$t->[5]+1900;
		$t->[4]=_time_func_is_int($rh_time->{'month'})?$rh_time->{'month'}:$t->[4]+1;
		$t->[3]=_time_func_is_int($rh_time->{'day'})?$rh_time->{'day'}:$t->[3];
		$t->[2]=_time_func_is_int($rh_time->{'hour'})?$rh_time->{'hour'}:$t->[2];
		$t->[1]=_time_func_is_int($rh_time->{'min'})?$rh_time->{'min'}:$t->[1];
		$t->[0]=_time_func_is_int($rh_time->{'sec'})?$rh_time->{'sec'}:$t->[0];
#TODO if new time is not valid
		return sprintf('%04s-%02s-%02s %02s:%02s:%02s',$t->[5],$t->[4],$t->[3],$t->[2],$t->[1],$t->[0]);
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'datetime_set: param count should be 2');
	}
}

sub inet_aton{
	local $_=shift;
	if(!defined($_)){return 0;}
	if(/^\s*(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\s*$/){
		if($1>=0&&$1<256&&$2>=0&&$2<256&&$3>=0&&$3<256&&$4>=0&&$4<256){
			return $1*16777216+$2*65536+$3*256+$4;
		};
	};
	return 0;
}

sub inet_ntoa{
	my $n=shift;
	if(!defined($n)){return '0.0.0.0';}
    my @ip;
    for(0..3){
        $ip[3-$_] = $n%256;
        $n = ($n - $ip[3-$_])/256;
    }
	return join '.', @ip;
}

sub filter_hash_restrict{
	my $param_count=scalar(@_);
	if($param_count==2){
		my $rs={};
		foreach(@{$_[1]}){
			if(exists($_[0]->{$_})){
				$rs->{$_}=$_[0]->{$_}
			}else{
#				CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'filter_hash_restrict: key not found');
			}
		}	
		return $rs;
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'filter_hash_restrict: param count should be 2');
	}
}

sub html_gen_hidden{
	my $param_count=scalar(@_);
	if($param_count==2){
		my $tmpl='<input type=hidden name="<TMPL_VAR ESCAPE=HTML NAME="n">" value="<TMPL_VAR ESCAPE=HTML NAME="v">">';
		 my $t = HTML::Template->new(scalarref => \$tmpl);
		 $t->param(n=>$_[0],v=>$_[1]);
		 return $t->output();
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'filter_hash_restrict: param count should be 2');
	}
}

1;
