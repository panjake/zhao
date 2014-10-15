package EasyDBAccess;
use strict;
use warnings(FATAL=>'all');

#===ERR_CODE
#NO_ERROR     0
#NO_LINE      1
#PARAM_ERR    2
#CONN_ERR     3
#PREPARE_ERR  4
#EXEC_ERR     5

#===================================
#===Author  : qian.yu            ===
#===Email   : foolfish@cpan.org  ===
#===MSN     : qian.yu@adways.net ===
#===QQ      : 19937129           ===
#===Homepage: www.lua.cn         ===
#===================================

#===================================
#===Require : DBI DBD::Mysql Encode FileHandle
#===Require2: EasyHandler
#===================================

#===2.2.2(2005-09-07): use socket to connect mysql server
#===2.2.1(2005-07-01): rename errcode to err_code, add err_code ER_PARSE_ERROR
#===2.2.0(2005-07-01): return use wantarray
#===2.1.1(2005-04-28): add errcode function
#===2.1.0            : improve id function
#===2.0.4            : add once function
#===2.0.3            : some small bug fix
#===2.0.2            : encoding bug fix
#===2.0.1            : so that u can change $_debug in runtime >>my $_debug=1; => our $_debug=1;

use DBI;
use Encode;
use FileHandle;

my $_pkg_name=__PACKAGE__;
sub foo{1};

#===========================================
#=== options
	#===if you set $_DEBUG=false then no "die"
	our $_DEBUG=0;

	#===if you set $_SETNAMES=false then won't do set names when connect
	our $_SETNAMES=1;
#============================================

#============================================
#===names
	#===name for mysql version
	my $_name_mysql_ver_3='3.23';
	my $_name_mysql_ver_41='4.1';

	#===use the name of EasyTool if exist
	my $_name_utf8=(defined(&EasyTool::foo)&&defined(&EasyTool::_name_utf8))?&EasyTool::_name_utf8:'utf8';
#============================================

#============================================
my $_dbh_attr_default = {PrintError=>0,RaiseError=>0,LongReadLen=>1048576,FetchHashKeyName=>'NAME_lc',AutoCommit=>1};
my $_mysql_conn_attrib= ['host','port','database','mysql_client_found_rows','mysql_compression','mysql_connect_timeout','mysql_read_default_file','mysql_read_default_group','mysql_socket','mysql_ssl','mysql_ssl_client_key','mysql_ssl_client_cert','mysql_ssl_ca_file','mysql_ssl_ca_path','mysql_ssl_cipher','mysql_local_infile'];
my $_mysql_error_code_map={
	ER_DUP_ENTRY=>1062,			#Duplicate entry for key
	ER_PARSE_ERROR=>1064		#SQL string parse error
};
#============================================

our $_ID_NO_INSTALL=0;
our $_ID_CONTINUE=1;#default
our $_ID_UNIQUE=2;
our $_ID_UNINSTALL=99;

our $_ERR_NO_INSTALL=0;
our $_ERR_INSTALL=1;#default
our $_ERR_UNINSTALL=99;

our $_ONCE=0;#ignore the next function's error

my $_str_func_new='new';
my $_str_func_id='id';
my $_str_func_execute='execute';
my $_str_func_select='select';
my $_str_func_select_one='select_one';
my $_str_func_select_col='select_col';
my $_str_func_select_row='select_row';
my $_str_new_param_err='only can accept one or two param';
my $_str_new_conn_err='connect to database failed';
my $_str_sql_null_err='sql string is null';
my $_str_inline_null_err='null in inline param';
my $_str_no_line='NO_LINE';
my $_str_param_err='PARAM_ERR';
my $_str_conn_err='CONN_ERR';
my $_str_prepare_err='PREPARE_ERR';
my $_str_exec_err='EXEC_ERR';
my $_str_dbh_do_err='when call $dbh->do, system return fause';
my $_str_dbh_prepare_err='when call $dbh->prepare, system return fause';
my $_str_dbh_execute_err='when call $dbh->execute, system return fause';
my $_str_dbh_fetchall_arrayref_err='when call $sth->fetchall_arrayref, system return fause, maybe u use select on a none select sql';
my $_str_dbh_fetchrow_arrayref_err_a='when call $sth->fetchrow_hashref, system return fause, maybe u use select on a none select sql';
my $_str_dbh_fetchrow_arrayref_err_b='when call $dbh->fetchrow_arrayref, system return fause, maybe u try to get one row from a result set with no row in it';
my $_str_dbh_fetchrow_hashref_err_a='when call $sth->fetchrow_hashref, system return fause, maybe u use select on a none select sql';
my $_str_dbh_fetchrow_hashref_err_b='when call $sth->fetchrow_hashref, system return fause, maybe u try to get one row from a result set with no row in it';

sub new {
	my $class = shift;
	my ($param,$option);
	
	my $once=($_ONCE==1)?1:0;
	if($once){$_ONCE=0 if $_ONCE==1;};
	
	my $param_count=scalar(@_);
	if($param_count==1){
		($param)=@_;
	}elsif($param_count==2){
		($param,$option)=@_;
	}else{
		my ($err_code,$err_detail)=(2,'');
		my $sys_err='';
		my $param="ParamInfo :\n"._dump([@_])."\n";
		my $caller='';
		for(my $i=0;;$i++){
			my $ra_caller_info=[caller($i)];
			if(scalar(@$ra_caller_info)==0){last;}
			else{
				$caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
			}
		}
		$caller="CallerInfo:\n$caller";
		$err_detail="$_pkg_name\:\:$_str_func_new\(\) throw $_str_param_err\nHelpNote  : $_str_new_param_err\n$sys_err$param$caller\n";
		if($_DEBUG&&!$once){
			CORE::die $err_detail;
		}
		return wantarray?(undef,$err_code,$err_detail,$_pkg_name):undef;
	}

	#===make a copy of $param
	$param={%$param};

	my $self = bless {},$class;
	my $dbh;
	my $type=delete $param->{'type'}||'mysql';
	my $die_handler=defined($option)?$option->{die_handler}:undef;
	my $auto_die_handler=defined($option)?$option->{auto_die_handler}:undef;
	if(defined($auto_die_handler)){
		$die_handler=$auto_die_handler;
		$auto_die_handler=1;
	}
	if(!defined($auto_die_handler)&&!defined($die_handler)){
		if(defined($option)&&defined($option->{err_file})){
			$die_handler=EasyHandler->new(\&die_to_file,[$option->{err_file}]);
		}
	}

	my ($version,$ver,$unicode,$encoding);

	if($type eq 'mysql'){
		my $usr=_IFNULL(delete($param->{usr}),'root');
		my $pass=_IFNULL(delete($param->{pass}),'');
		my $dsn;
		my $socket=delete($param->{mysql_socket});
		if(defined($socket)){
			$encoding=_IFNULL(delete($param->{encoding}),$_name_utf8);
			$unicode=_IFNULL(delete($param->{unicode}),0);
			$version=delete $param->{version};
			my $extra_conn_attrib='';
			foreach(@$_mysql_conn_attrib){
				if(defined($param->{$_})){
					$extra_conn_attrib.=$_.'='.(delete $param->{$_}).';';
				}
			}
			$dsn ='DBI:mysql:'.$extra_conn_attrib.'mysql_socket='.$socket;
		}else{
			my $host=_IFNULL(delete($param->{host}),'127.0.0.1');
			my $port=_IFNULL(delete($param->{port}),3306);
			$encoding=_IFNULL(delete($param->{encoding}),$_name_utf8);
			$unicode=_IFNULL(delete($param->{unicode}),0);
			$version=delete $param->{version};
			my $extra_conn_attrib='';
			foreach(@$_mysql_conn_attrib){
				if(defined($param->{$_})){
					$extra_conn_attrib.=$_.'='.(delete $param->{$_}).';';
				}
			}
			$dsn ='DBI:mysql:host='.$host.';'.$extra_conn_attrib.'port='.$port;
		}
		
		#===merge default attrib and user set attrib
		my $attr={%$_dbh_attr_default};
		while(my ($k,$v)=each %$param){$attr->{$k}=$v;}

		#===$param now no use at all,so destroy it
		undef %$param;

		#===try to connect
        $dbh = DBI->connect($dsn,$usr,$pass,$attr);
        $self->{conn} = [$dsn,$usr,$pass,$attr];

		#===connect to database failed
		if(!defined($dbh)){
			my ($err_code,$err_detail)=(3,'');
			my $sys_err=defined(&DBI::errstr)?"ErrString : ".&DBI::errstr."\n":'';
			my $param="ParamInfo :\n"._dump([@_])."\n";
			my $caller='';
			for(my $i=0;;$i++){
				my $ra_caller_info=[caller($i)];
				if(scalar(@$ra_caller_info)==0){last;}
				else{
					$caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
				}
			}
			$caller="CallerInfo:\n$caller";
			$err_detail="$_pkg_name\:\:$_str_func_new\(\) throw $_str_conn_err\nHelpNote  : $_str_new_conn_err\n$sys_err$param$caller\n";
			if($_DEBUG&&!$once){
				if(defined($die_handler)){
					$die_handler->execute($err_code,$err_detail,$_pkg_name);
				}else{
					CORE::die $err_detail;
				}
			}
			return wantarray?(undef,$err_code,$err_detail,$_pkg_name):undef;
		}

		#===auto set error handler
		if($auto_die_handler){
			$die_handler->set(\&EasyDBAccess::die,[$self]);
		}

		#===get database version
		if(!defined($version)){
			$version=$dbh->selectrow_arrayref("SHOW VARIABLES LIKE 'VERSION'")->[1];
		}
		$ver=substr($version,0,3);
		
		#===if version>4.1 then set charset
		if($ver>=$_name_mysql_ver_41&&$_SETNAMES){
			$dbh->do("SET NAMES '$encoding'");
		}
	}else{CORE::die "$_pkg_name\:\:$_str_func_new\(\) unknow database type";}

	$self->{dbh}=$dbh;
	$self->{type}=$type;
	$self->{ver}=$ver;
	$self->{version}=$version;
	$self->{die_handler}=$die_handler;
	$self->{unicode}=$unicode;
	$self->{encoding}=$encoding;
	$self->{once}=0;#ignore the next function's error
    $self->{long} = $option->{long};
	return wantarray?($self,0,undef,$_pkg_name):$self;
}

sub dbh{return $_[0]->{dbh};}
sub close{undef $_[0];return 1;}
sub type{return $_[0]->{type};}
sub once{
	my ($self)=@_;
	if(ref $self eq $_pkg_name){
		$self->{once}=1;
	}else{
		$_ONCE=1;
	}
}

sub install{
	my ($self,$option)=@_;
	if($self->{type} eq 'mysql'){
		my $id_option=defined($option->{id})?$option->{id}:$_ID_CONTINUE;
		if($id_option==$_ID_NO_INSTALL){

		}elsif($id_option==$_ID_CONTINUE){
			$self->{dbh}->do('DROP TABLE IF EXISTS RES;');
			$self->{dbh}->do('CREATE TABLE RES(ATTRIB VARCHAR(255) NOT NULL,ID INT NOT NULL,PRIMARY KEY (ATTRIB));');
		}elsif($id_option==$_ID_UNINSTALL){
			$self->{dbh}->do('DROP TABLE IF EXISTS RES;');
		}else{
			$self->{dbh}->do('DROP TABLE IF EXISTS RES;');
			$self->{dbh}->do('CREATE TABLE RES(ATTRIB VARCHAR(255) NOT NULL,ID INT NOT NULL,PRIMARY KEY (ATTRIB));');
		}

		my $err_option=defined($option->{err})?$option->{err}:$_ERR_NO_INSTALL;
		if($err_option==$_ERR_NO_INSTALL){

		}elsif($err_option==$_ERR_INSTALL){
			$self->{dbh}->do('DROP TABLE IF EXISTS ERR;');
			$self->{dbh}->do('CREATE TABLE ERR(ID INT NOT NULL AUTO_INCREMENT,PKG VARCHAR(255) DEFAULT NULL,CODE VARCHAR(255) DEFAULT NULL,DETAIL TEXT NOT NULL,LEVEL INT NOT NULL,RECORD_TIME INT NOT NULL,PRIMARY KEY (ID));');
		}elsif($err_option==$_ERR_UNINSTALL){
			$self->{dbh}->do('DROP TABLE IF EXISTS ERR;');
		}else{
			
		}
	}else{CORE::die $_pkg_name.':install() unknow database type';}
	return 1;
}

sub id{
	my $self=shift;
	if($self->{type} eq 'mysql'){
		if(defined($_[1])&&($_[1]>1)){
			my $rc=$self->{dbh}->do('UPDATE RES SET ID=LAST_INSERT_ID(ID+?) WHERE ATTRIB=?;',undef,$_[1],defined($_[0])?$_[0]:'ANON');
			if($rc==0){
				$self->{dbh}->do('INSERT INTO RES(ATTRIB,ID) VALUES(?,0);',undef,defined($_[0])?$_[0]:'ANON');
				$self->{dbh}->do('UPDATE RES SET ID=LAST_INSERT_ID(ID+?) WHERE ATTRIB=?;',undef,$_[1],defined($_[0])?$_[0]:'ANON');
			}
			my $id=$self->{dbh}->selectrow_arrayref('SELECT LAST_INSERT_ID();')->[0];
			return $id;
		}
		my $rc=$self->{dbh}->do('UPDATE RES SET ID=LAST_INSERT_ID(ID+1) WHERE ATTRIB=?;',undef,defined($_[0])?$_[0]:'ANON');
		if($rc==0){
			$self->{dbh}->do('INSERT INTO RES(ATTRIB,ID) VALUES(?,1);',undef,defined($_[0])?$_[0]:'ANON');
			return 1;
		}
		my $id=$self->{dbh}->selectrow_arrayref('SELECT LAST_INSERT_ID();')->[0];
		return $id;
	}else{CORE::die "$_pkg_name\:\:$_str_func_id\(\) unknow database type;";}
}

sub die{
	my $self = ref $_[0] eq $_pkg_name?shift:undef;
	my ($err_pkg,$err_code,$err_detail,$record_time)=(undef,undef,undef,CORE::time);
	my $param_count=scalar(@_);
	if($param_count==1){
		($err_detail)=@_;
	}elsif($param_count==3){
		($err_code,$err_detail,$err_pkg)=@_;
	}elsif($param_count==4){
		($err_code,$err_detail,$err_pkg,$record_time)=@_;
	}else{
		CORE::die "$_pkg_name\:\:$_str_func_id\(\) param error;";
	}

	if(!defined($self)){
		CORE::die $err_detail;
	}else{
		$self->{dbh}->do('INSERT INTO ERR(ID,PKG,CODE,DETAIL,LEVEL,RECORD_TIME) VALUES(DEFAULT,?,?,?,1,?);',undef,$err_pkg,$err_code,$err_detail,$record_time);
	}
}

sub _replace {
	while(my($k,$v)=each %{$_[1]}){
		if(!defined($v)){return 0;}
		$_[0]=~s/\Q%$k\E/$v/g;
	}
	return 1;
}

sub _encode{
	if(defined($_[2])){
		$_[0]=Encode::encode($_[2],$_[0]);
		my $ra=[];
		foreach(@{$_[1]}){
			push @$ra,utf8::is_utf8($_)?Encode::encode($_[2],$_):$_;
		}
		$_[1]=$ra;
	}else{
		&utf8::encode($_[0]);
		my $ra=[];
		foreach(@{$_[1]}){
			if(utf8::is_utf8($_)){&utf8::encode($_);}
			push @$ra,$_;
		}
		$_[1]=$ra;
	}
}

sub _decode{
	my $ref=ref $_[0];
	if($ref eq 'ARRAY'){
		foreach (@{$_[0]}){
			_decode($_,$_[1]);
		}
	}elsif($ref eq 'HASH'){
		foreach (keys(%{$_[0]})){
			my $k=$_;
			_decode($k,$_[1]);
			my $v=delete $_[0]->{$_};
			_decode($v,$_[1]);
			$_[0]->{$k}=$v;
		}
	}else{
		if(defined($_[1])){
			$_[0]=Encode::decode($_[1],$_[0]);
		}else{
			&utf8::decode($_[0]);
		}
	}
}

# put a string value in double quotes
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

sub _dump{
	my $max_line=80;
	my $param_count=scalar(@_);
	my ($flag,$str1,$str2);
	if($param_count==1){
		my $data=$_[0];
		my $type=ref $data;
		if($type eq 'ARRAY'){
			my $strs=[];
			foreach(@$data){push @$strs,_dump($_);}
			
			$str1='[';
			$flag=0;
			foreach(@$strs){$str1.=$_.', ';$flag=1;}
			if($flag==1){chop($str1);chop($str1);}
			$str1.=']';

			$str2='[';
			foreach(@$strs){s/\n/\n\x20\x20/g;$str2.="\n\x20\x20".$_.',';}
			$str2.="\n]";
			
			return length($str1)>$max_line?$str2:$str1;
		}elsif($type eq 'HASH'){
			my $strs=[];
			foreach(keys(%$data)){push @$strs,[qquote($_),_dump($data->{$_})];}
			
			$str1='{';
			$flag=0;
			foreach(@$strs){$str1.="$_->[0] => $_->[1], ";$flag=1;}
			if($flag==1){chop($str1);chop($str1);}
			$str1.='}';

			$str2='{';
			foreach(@$strs){ $_->[1]=~s/\n/\n\x20\x20/g;
				$str2.="\n\x20\x20$_->[0] => $_->[1],";}
			$str2.="\n}";
			
			return length($str1)>$max_line?$str2:$str1;
		}elsif($type eq ''){
			$flag=0;
			if(!defined($data)){return 'undef'};
			eval{if($data eq int $data){$flag=1;}};
			if($@){undef $@;}
			if($flag==0){return qquote($data);}
			elsif($flag==1){return $data;}
		}else{
			return ''.$data;
		}
	}else{
		my $strs=[];
		foreach(@_){push @$strs,_dump($_);}

		$str1='(';
		$flag=0;
		foreach(@$strs){$str1.=$_.', ';$flag=1;}
		if($flag==1){chop($str1);chop($str1);}
		$str1.=')';

		$str2='(';
		foreach(@$strs){s/\n/\n\x20\x20/g;$str2.="\n\x20\x20".$_.',';}
		$str2.="\n)";
			
		return length($str1)>$max_line?$str2:$str1;
	}
}

sub _IFNULL{
	defined($_[0])?$_[0]:$_[1];
}

sub build_array{
	my ($filter,$hash,$array)=@_;
	my $ra=[];
	$array=defined($array)?$array=[@$array]:[];
	my $err_code=0;
	foreach(@$filter){
		if(defined($_)&&($_ ne '?')){
			if(exists($hash->{$_})){
				push @$ra,$hash->{$_};
			}else{
				$err_code=1;
				push @$ra,undef;
			}
		}else{
			push @$ra,shift @$array;
		}
	}
	return wantarray ? ($ra,$err_code):$ra;
}

sub build_update{
	my ($filter,$hash)=@_;;
	my $str='';
	my $ra_bind_param=[];
	my $flag=0;
	foreach(@$filter){
		$_=lc($_);
		if(exists($hash->{$_})){
			push @$ra_bind_param,$hash->{$_};
			$str.=uc($_).'=?,';
			$flag++;
		}
	}
	my $str2=$str;
	if($flag!=0){chop($str2)};
	return wantarray ? ($str2,$ra_bind_param,$flag,$str):$str;
}

sub die_to_file{
	my $file_path= shift;
	my ($err_pkg,$err_code,$err_detail,$record_time)=(undef,undef,undef,CORE::time);
	my $param_count=scalar(@_);
	if($param_count==1){
		($err_detail)=@_;
	}elsif($param_count==3){
		($err_code,$err_detail,$err_pkg)=@_;
	}elsif($param_count==4){
		($err_code,$err_detail,$err_pkg,$record_time)=@_;
	}else{
		CORE::die "die_to_file param error;";
	}

	$_=[localtime($record_time)];
	my $prefix="#####".sprintf('%04s-%02s-%02s %02s:%02s:%02s',$_->[5]+1900,$_->[4]+1,$_->[3],$_->[2],$_->[1],$_->[0])."\n";

	my $result=append_file($file_path,$prefix.$err_detail."\n");
	if($result){
		#log succ
	}else{
		CORE::die $err_detail;
	}
}
sub err_code{
	if(!defined($_[0])){
		return '';
	}elsif($_[0] eq $_pkg_name){
		shift;
	}elsif(ref $_[0] eq $_pkg_name){
		shift;
	}else{
	
	}
	return $_mysql_error_code_map->{$_[0]};
}
sub append_file{
	my ($file_path,$data)=@_;

	my $fh=FileHandle->new($file_path,'a');
	if(!defined($fh)){return undef};
	$fh->syswrite($data);
	$fh->close();
}

DESTROY{
	if(defined($_[0]->{dbh})){
		$_[0]->{dbh}->disconnect();
		undef $_[0]->{dbh};
	}
}

sub execute{
	my $self=shift;
	my ($sql_str,$bind_param,$inline_param)=@_;
	if(defined($bind_param)&&(ref($bind_param) eq 'ARRAY')){
	}elsif(defined($bind_param)&&(ref($bind_param) eq 'HASH')){
		$inline_param=$bind_param;
		$bind_param=[];
	}else{
		$bind_param=[];
	}
	my $succ=1;
	
	my $once=($_ONCE==1||$self->{once}==1)?1:0;
	if($once){$_ONCE=0 if $_ONCE==1;$self->{once}=0 if $self->{once}==1};

	if(!defined($sql_str)){
		my ($err_code,$err_detail,$die_handler)=(2,'',$self->{die_handler});
		my $sys_err='';
		my $param="ParamInfo :\n"._dump([@_])."\n";
		my $caller='';
		for(my $i=0;;$i++){
			my $ra_caller_info=[caller($i)];
			if(scalar(@$ra_caller_info)==0){last;}
			else{
				$caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
			}
		}
		$caller="CallerInfo:\n$caller";
		$err_detail="$_pkg_name\:\:$_str_func_execute\(\) throw $_str_param_err\nHelpNote  : $_str_sql_null_err\n$sys_err$param$caller\n";
		if($_DEBUG&&!$once){
			if(defined($die_handler)){
				$die_handler->execute($err_code,$err_detail,$_pkg_name);
			}else{
				CORE::die $err_detail;
			}
		}
		return wantarray?(undef,$err_code,$err_detail,$_pkg_name):undef;
	}

	if(defined($inline_param)){
		$succ=_replace($sql_str,$inline_param);
	};

	if(!$succ){
		my($err_code,$err_detail,$die_handler)=(2,'',$self->{die_handler});
		my $sys_err='';
		my $param="ParamInfo :\n"._dump([@_])."\n";
		my $caller='';
		for(my $i=0;;$i++){
			my $ra_caller_info=[caller($i)];
			if(scalar(@$ra_caller_info)==0){last;}
			else{
				$caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
			}
		}
		$caller="CallerInfo:\n$caller";
		$err_detail="$_pkg_name\:\:$_str_func_execute\(\) throw $_str_param_err\nHelpNote  : $_str_inline_null_err\n$sys_err$param$caller\n";
		if($_DEBUG&&!$once){
			if(defined($die_handler)){
				$die_handler->execute($err_code,$err_detail,$_pkg_name);
			}else{
				CORE::die $err_detail;
			}
		}	
		return wantarray?(undef,$err_code,$err_detail,$_pkg_name):undef;
	}
	
	my $unicode=$self->{unicode};
	my $dst_encoding=$self->{encoding} eq $_name_utf8?undef:$self->{encoding};
	if($unicode){_encode($sql_str,$bind_param,$dst_encoding);}
	$succ=$self->{dbh}->do($sql_str,undef,@$bind_param);
    
    # save current dbh error info 
    my $dbh_err = $self->{dbh}->err;
    my $dbh_errstr = $self->{dbh}->errstr;
    if($self->{dbh}->err and !$self->is_connect()){
        $self->re_connect();
        $succ=$self->{dbh}->do($sql_str,undef,@$bind_param);
        # replace the new dbh error info
        $dbh_err = $self->{dbh}->err;
        $dbh_errstr = $self->{dbh}->errstr;
    }
    
    # $dbh_err $dbh_errstr
	if($dbh_err){
		my ($err_code,$err_detail,$die_handler)=(5,'',$self->{die_handler});
		my $sys_err=defined($dbh_errstr)?"ErrString : ".$dbh_errstr."\n":'';
		my $param="ParamInfo :\n"._dump([$sql_str,@$bind_param])."\n";
		my $caller='';
		for(my $i=0;;$i++){
			my $ra_caller_info=[caller($i)];
			if(scalar(@$ra_caller_info)==0){last;}
			else{
				$caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
			}
		}
		$caller="CallerInfo:\n$caller";
		$err_detail="$_pkg_name\:\:$_str_func_execute\(\) throw $_str_exec_err\nHelpNote  : $_str_dbh_do_err\n$sys_err$param$caller\n";
		if($_DEBUG&&!$once){
			if(defined($die_handler)){
				$die_handler->execute($err_code,$err_detail,$_pkg_name);
			}else{
				CORE::die $err_detail;
			}
		}
		return wantarray?($dbh_err,$err_code,$err_detail,$_pkg_name):$dbh_errstr;
	}
	return wantarray?($succ,0,undef,$_pkg_name):$succ;
}

sub select {
	my $self=shift;
	my ($sql_str,$bind_param,$inline_param)=@_;
	if(defined($bind_param)&&(ref($bind_param) eq 'ARRAY')){
	}elsif(defined($bind_param)&&(ref($bind_param) eq 'HASH')){
		$inline_param=$bind_param;
		$bind_param=[];
	}else{
		$bind_param=[];
	}
	my $succ=1;

	my $once=($_ONCE==1||$self->{once}==1)?1:0;
	if($once){$_ONCE=0 if $_ONCE==1;$self->{once}=0 if $self->{once}==1};

	if(!defined($sql_str)){
		my ($err_code,$err_detail,$die_handler)=(2,'',$self->{die_handler});
		my $sys_err='';
		my $param="ParamInfo :\n"._dump([@_])."\n";
		my $caller='';
		for(my $i=0;;$i++){
			my $ra_caller_info=[caller($i)];
			if(scalar(@$ra_caller_info)==0){last;}
			else{
				$caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
			}
		}
		$caller="CallerInfo:\n$caller";
		$err_detail="$_pkg_name\:\:$_str_func_select\(\) throw $_str_param_err\nHelpNote  : $_str_sql_null_err\n$sys_err$param$caller\n";
		if($_DEBUG&&!$once){
			if(defined($die_handler)){
				$die_handler->execute($err_code,$err_detail,$_pkg_name);
			}else{
				CORE::die $err_detail;
			}
		}	
		return wantarray?(undef,$err_code,$err_detail,$_pkg_name):undef;
	}

	if(defined($inline_param)){
		$succ=_replace($sql_str,$inline_param);
	};

	if(!$succ){
		my($err_code,$err_detail,$die_handler)=(2,'',$self->{die_handler});
		my $sys_err='';
		my $param="ParamInfo :\n"._dump([@_])."\n";
		my $caller='';
		for(my $i=0;;$i++){
			my $ra_caller_info=[caller($i)];
			if(scalar(@$ra_caller_info)==0){last;}
			else{
				$caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
			}
		}
		$caller="CallerInfo:\n$caller";
		$err_detail="$_pkg_name\:\:$_str_func_select\(\) throw $_str_param_err\nHelpNote  : $_str_inline_null_err\n$sys_err$param$caller\n";
		if($_DEBUG&&!$once){
			if(defined($die_handler)){
				$die_handler->execute($err_code,$err_detail,$_pkg_name);
			}else{
				CORE::die $err_detail;
			}
		}	
		return wantarray?(undef,$err_code,$err_detail,$_pkg_name):undef;
	}

	my $unicode=$self->{unicode};
	my $dst_encoding=$self->{encoding} eq $_name_utf8?undef:$self->{encoding};
	if($unicode){_encode($sql_str,$bind_param,$dst_encoding);}

	my $sth = $self->{dbh}->prepare($sql_str);
	$succ = $sth->execute(@$bind_param);
    
    # save current sth error info 
    if($sth->err and !$self->is_connect()){
        $self->re_connect();
        $sth = $self->{dbh}->prepare($sql_str);
        $succ = $sth->execute(@$bind_param);
    }
    
	if($sth->err){
		my ($err_code,$err_detail,$die_handler)=(5,'',$self->{die_handler});
		my $sys_err=defined($sth->errstr)?"ErrString : ".$sth->errstr."\n":'';
		$sth->finish();
		my $param="ParamInfo :\n"._dump([$sql_str,@$bind_param])."\n";
		my $caller='';
		for(my $i=0;;$i++){
			my $ra_caller_info=[caller($i)];
			if(scalar(@$ra_caller_info)==0){last;}
			else{
				$caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
			}
		}
		$caller="CallerInfo:\n$caller";
		$err_detail="$_pkg_name\:\:$_str_func_select\(\) throw $_str_exec_err\nHelpNote  : $_str_dbh_execute_err\n$sys_err$param$caller\n";
		if($_DEBUG&&!$once){
			if(defined($die_handler)){
				$die_handler->execute($err_code,$err_detail,$_pkg_name);
			}else{
				CORE::die $err_detail;
			}
		}
		return wantarray?(undef,$err_code,$err_detail,$_pkg_name):undef;
	}

    $succ=$sth->fetchall_arrayref({});
	if($sth->err){
		my ($err_code,$err_detail,$die_handler)=(5,'',$self->{die_handler});
		my $sys_err=defined($sth->errstr)?"ErrString : ".$sth->errstr."\n":'';
		$sth->finish();
		my $param="ParamInfo :\n"._dump([$sql_str,@$bind_param])."\n";
		my $caller='';
		for(my $i=0;;$i++){
			my $ra_caller_info=[caller($i)];
			if(scalar(@$ra_caller_info)==0){last;}
			else{
				$caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
			}
		}
		$caller="CallerInfo:\n$caller";
		$err_detail="$_pkg_name\:\:$_str_func_select\(\) throw $_str_exec_err\nHelpNote  : $_str_dbh_fetchall_arrayref_err\n$sys_err$param$caller\n";
		if($_DEBUG&&!$once){
			if(defined($die_handler)){
				$die_handler->execute($err_code,$err_detail,$_pkg_name);
			}else{
				CORE::die $err_detail;
			}
		}
		return wantarray?(undef,$err_code,$err_detail,$_pkg_name):undef;
	}
	$sth->finish();
	if($unicode){_decode($succ,$dst_encoding);};
	return wantarray?($succ,0,undef,$_pkg_name):$succ;
}


sub select_row{
	my $self=shift;
	my ($sql_str,$bind_param,$inline_param)=@_;
	if(defined($bind_param)&&(ref($bind_param) eq 'ARRAY')){
	}elsif(defined($bind_param)&&(ref($bind_param) eq 'HASH')){
		$inline_param=$bind_param;
		$bind_param=[];
	}else{
		$bind_param=[];
	}
	my $succ=1;

	my $once=($_ONCE==1||$self->{once}==1)?1:0;
	if($once){$_ONCE=0 if $_ONCE==1;$self->{once}=0 if $self->{once}==1};

	if(!defined($sql_str)){
		my ($err_code,$err_detail,$die_handler)=(2,'',$self->{die_handler});
		my $sys_err='';
		my $param="ParamInfo :\n"._dump([@_])."\n";
		my $caller='';
		for(my $i=0;;$i++){
			my $ra_caller_info=[caller($i)];
			if(scalar(@$ra_caller_info)==0){last;}
			else{
				$caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
			}
		}
		$caller="CallerInfo:\n$caller";
		$err_detail="$_pkg_name\:\:$_str_func_select_row\(\) throw $_str_param_err\nHelpNote  : $_str_sql_null_err\n$sys_err$param$caller\n";
		if($_DEBUG&&!$once){
			if(defined($die_handler)){
				$die_handler->execute($err_code,$err_detail,$_pkg_name);
			}else{
				CORE::die $err_detail;
			}
		}	
		return wantarray?(undef,$err_code,$err_detail,$_pkg_name):undef;
	}

	if(defined($inline_param)){
		$succ=_replace($sql_str,$inline_param);
	};

	if(!$succ){
		my($err_code,$err_detail,$die_handler)=(2,'',$self->{die_handler});
		my $sys_err='';
		my $param="ParamInfo :\n"._dump([@_])."\n";
		my $caller='';
		for(my $i=0;;$i++){
			my $ra_caller_info=[caller($i)];
			if(scalar(@$ra_caller_info)==0){last;}
			else{
				$caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
			}
		}
		$caller="CallerInfo:\n$caller";
		$err_detail="$_pkg_name\:\:$_str_func_select_row\(\) throw $_str_param_err\nHelpNote  : $_str_inline_null_err\n$sys_err$param$caller\n";
		if($_DEBUG&&!$once){
			if(defined($die_handler)){
				$die_handler->execute($err_code,$err_detail,$_pkg_name);
			}else{
				CORE::die $err_detail;
			}
		}	
		return wantarray?(undef,$err_code,$err_detail,$_pkg_name):undef;
	}

	my $unicode=$self->{unicode};
	my $dst_encoding=$self->{encoding} eq $_name_utf8?undef:$self->{encoding};
	if($unicode){_encode($sql_str,$bind_param,$dst_encoding);}

	my $sth = $self->{dbh}->prepare($sql_str);
	$succ = $sth->execute(@$bind_param);
    
    # save current sth error info 
    if($sth->err and !$self->is_connect()){
        $self->re_connect();
        $sth = $self->{dbh}->prepare($sql_str);
        $succ = $sth->execute(@$bind_param);
    }
    
	if($sth->err){
		my ($err_code,$err_detail,$die_handler)=(5,'',$self->{die_handler});
		my $sys_err=defined($sth->errstr)?"ErrString : ".$sth->errstr."\n":'';
		$sth->finish();
		my $param="ParamInfo :\n"._dump([$sql_str,@$bind_param])."\n";
		my $caller='';
		for(my $i=0;;$i++){
			my $ra_caller_info=[caller($i)];
			if(scalar(@$ra_caller_info)==0){last;}
			else{
				$caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
			}
		}
		$caller="CallerInfo:\n$caller";
		$err_detail="$_pkg_name\:\:$_str_func_select_row\(\) throw $_str_exec_err\nHelpNote  : $_str_dbh_execute_err\n$sys_err$param$caller\n";
		if($_DEBUG&&!$once){
			if(defined($die_handler)){
				$die_handler->execute($err_code,$err_detail,$_pkg_name);
			}else{
				CORE::die $err_detail;
			}
		}
		return wantarray?($succ,$err_code,$err_detail,$_pkg_name):$succ;
	}

	$succ=$sth->fetchrow_hashref();
	if($sth->err){
		my ($err_code,$err_detail,$die_handler)=(5,'',$self->{die_handler});
		my $sys_err=defined($sth->errstr)?"ErrString : ".$sth->errstr."\n":'';
		$sth->finish();
		my $param="ParamInfo :\n"._dump([$sql_str,@$bind_param])."\n";
		my $caller='';
		for(my $i=0;;$i++){
			my $ra_caller_info=[caller($i)];
			if(scalar(@$ra_caller_info)==0){last;}
			else{
				$caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
			}
		}
		$caller="CallerInfo:\n$caller";
		$err_detail="$_pkg_name\:\:$_str_func_select_row\(\) throw $_str_exec_err\nHelpNote  : $_str_dbh_fetchrow_hashref_err_a\n$sys_err$param$caller\n";
		if($_DEBUG&&!$once){
			if(defined($die_handler)){
				$die_handler->execute($err_code,$err_detail,$_pkg_name);
			}else{
				CORE::die $err_detail;
			}
		}
		return wantarray?($succ,$err_code,$err_detail,$_pkg_name):$succ;
	}elsif(!$succ){
		my ($err_code,$err_detail,$die_handler)=(1,'',$self->{die_handler});
		my $sys_err='';
		$sth->finish();
		my $param='';
		my $caller='';
		$err_detail="$_pkg_name\:\:$_str_func_select_row\(\) throw $_str_no_line\nHelpNote  : $_str_dbh_fetchrow_hashref_err_b\n$sys_err$param$caller\n";
		return wantarray?($succ,$err_code,$err_detail,$_pkg_name):$succ;
	}
	$sth->finish();
	if($unicode){_decode($succ,$dst_encoding);};
	return wantarray?($succ,0,undef,$_pkg_name):$succ;
}

sub select_one{
	my $self=shift;
	my ($sql_str,$bind_param,$inline_param)=@_;
	if(defined($bind_param)&&(ref($bind_param) eq 'ARRAY')){
	}elsif(defined($bind_param)&&(ref($bind_param) eq 'HASH')){
		$inline_param=$bind_param;
		$bind_param=[];
	}else{
		$bind_param=[];
	}
	my $succ=1;

	my $once=($_ONCE==1||$self->{once}==1)?1:0;
	if($once){$_ONCE=0 if $_ONCE==1;$self->{once}=0 if $self->{once}==1};

	if(!defined($sql_str)){
		my ($err_code,$err_detail,$die_handler)=(2,'',$self->{die_handler});
		my $sys_err='';
		my $param="ParamInfo :\n"._dump([@_])."\n";
		my $caller='';
		for(my $i=0;;$i++){
			my $ra_caller_info=[caller($i)];
			if(scalar(@$ra_caller_info)==0){last;}
			else{
				$caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
			}
		}
		$caller="CallerInfo:\n$caller";
		$err_detail="$_pkg_name\:\:$_str_func_select_one\(\) throw $_str_param_err\nHelpNote  : $_str_sql_null_err\n$sys_err$param$caller\n";
		if($_DEBUG&&!$once){
			if(defined($die_handler)){
				$die_handler->execute($err_code,$err_detail,$_pkg_name);
			}else{
				CORE::die $err_detail;
			}
		}	
		return (undef,$err_code,$err_detail,$_pkg_name,undef);
	}

	if(defined($inline_param)){
		$succ=_replace($sql_str,$inline_param);
	};

	if(!$succ){
		my($err_code,$err_detail,$die_handler)=(2,'',$self->{die_handler});
		my $sys_err='';
		my $param="ParamInfo :\n"._dump([@_])."\n";
		my $caller='';
		for(my $i=0;;$i++){
			my $ra_caller_info=[caller($i)];
			if(scalar(@$ra_caller_info)==0){last;}
			else{
				$caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
			}
		}
		$caller="CallerInfo:\n$caller";
		$err_detail="$_pkg_name\:\:$_str_func_select_one\(\) throw $_str_param_err\nHelpNote  : $_str_inline_null_err\n$sys_err$param$caller\n";
		if($_DEBUG&&!$once){
			if(defined($die_handler)){
				$die_handler->execute($err_code,$err_detail,$_pkg_name);
			}else{
				CORE::die $err_detail;
			}
		}	
		return (undef,$err_code,$err_detail,$_pkg_name,undef);
	}

	my $unicode=$self->{unicode};
	my $dst_encoding=$self->{encoding} eq $_name_utf8?undef:$self->{encoding};
	if($unicode){_encode($sql_str,$bind_param,$dst_encoding);}

	my $sth = $self->{dbh}->prepare($sql_str);
	$succ = $sth->execute(@$bind_param);
    
    # save current sth error info 
    if($sth->err and !$self->is_connect()){
        $self->re_connect();
        $sth = $self->{dbh}->prepare($sql_str);
        $succ = $sth->execute(@$bind_param);
    }
    
	if($sth->err){
		my ($err_code,$err_detail,$die_handler)=(5,'',$self->{die_handler});
		my $sys_err=defined($sth->errstr)?"ErrString : ".$sth->errstr."\n":'';
		$sth->finish();
		my $param="ParamInfo :\n"._dump([$sql_str,@$bind_param])."\n";
		my $caller='';
		for(my $i=0;;$i++){
			my $ra_caller_info=[caller($i)];
			if(scalar(@$ra_caller_info)==0){last;}
			else{
				$caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
			}
		}
		$caller="CallerInfo:\n$caller";
		$err_detail="$_pkg_name\:\:$_str_func_select_one\(\) throw $_str_exec_err\nHelpNote  : $_str_dbh_execute_err\n$sys_err$param$caller\n";
		if($_DEBUG&&!$once){
			if(defined($die_handler)){
				$die_handler->execute($err_code,$err_detail,$_pkg_name);
			}else{
				CORE::die $err_detail;
			}
		}
		return ($succ,$err_code,$err_detail,$_pkg_name,$succ);
	}

	$succ=$sth->fetchrow_arrayref();
	if($sth->err){
		my ($err_code,$err_detail,$die_handler)=(5,'',$self->{die_handler});
		my $sys_err=defined($sth->errstr)?"ErrString : ".$sth->errstr."\n":'';
		$sth->finish();
		my $param="ParamInfo :\n"._dump([$sql_str,@$bind_param])."\n";
		my $caller='';
		for(my $i=0;;$i++){
			my $ra_caller_info=[caller($i)];
			if(scalar(@$ra_caller_info)==0){last;}
			else{
				$caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
			}
		}
		$caller="CallerInfo:\n$caller";
		$err_detail="$_pkg_name\:\:$_str_func_select_one\(\) throw $_str_exec_err\nHelpNote  : $_str_dbh_fetchrow_arrayref_err_a\n$sys_err$param$caller\n";
		if($_DEBUG&&!$once){
			if(defined($die_handler)){
				$die_handler->execute($err_code,$err_detail,$_pkg_name);
			}else{
				CORE::die $err_detail;
			}
		}
		return wantarray?($succ,$err_code,$err_detail,$_pkg_name):$succ;
	}elsif(!$succ){
		my ($err_code,$err_detail,$die_handler)=(1,'',$self->{die_handler});
		my $sys_err='';
		$sth->finish();
		my $param='';
		my $caller='';
		$err_detail="$_pkg_name\:\:$_str_func_select_one\(\) $sql_str throw $_str_no_line\nHelpNote  : $_str_dbh_fetchrow_arrayref_err_b\n$sys_err$param$caller\n";
		return wantarray?($succ,$err_code,$err_detail,$_pkg_name):$succ;
	}
	$sth->finish();
	if($unicode){_decode($succ->[0],$dst_encoding);};
	return wantarray?($succ->[0],0,undef,$_pkg_name):$succ->[0];
}

sub select_col{
	my $self=shift;
	my ($sql_str,$bind_param,$inline_param)=@_;
	if(defined($bind_param)&&(ref($bind_param) eq 'ARRAY')){
	}elsif(defined($bind_param)&&(ref($bind_param) eq 'HASH')){
		$inline_param=$bind_param;
		$bind_param=[];
	}else{
		$bind_param=[];
	}
	my $succ=1;

	my $once=($_ONCE==1||$self->{once}==1)?1:0;
	if($once){$_ONCE=0 if $_ONCE==1;$self->{once}=0 if $self->{once}==1};

	if(!defined($sql_str)){
		my ($err_code,$err_detail,$die_handler)=(2,'',$self->{die_handler});
		my $sys_err='';
		my $param="ParamInfo :\n"._dump([@_])."\n";
		my $caller='';
		for(my $i=0;;$i++){
			my $ra_caller_info=[caller($i)];
			if(scalar(@$ra_caller_info)==0){last;}
			else{
				$caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
			}
		}
		$caller="CallerInfo:\n$caller";
		$err_detail="$_pkg_name\:\:$_str_func_select_col\(\) throw $_str_param_err\nHelpNote  : $_str_sql_null_err\n$sys_err$param$caller\n";
		if($_DEBUG&&!$once){
			if(defined($die_handler)){
				$die_handler->execute($err_code,$err_detail,$_pkg_name);
			}else{
				CORE::die $err_detail;
			}
		}	
		return wantarray?(undef,$err_code,$err_detail,$_pkg_name):undef;
	}

	if(defined($inline_param)){
		$succ=_replace($sql_str,$inline_param);
	};

	if(!$succ){
		my($err_code,$err_detail,$die_handler)=(2,'',$self->{die_handler});
		my $sys_err='';
		my $param="ParamInfo :\n"._dump([@_])."\n";
		my $caller='';
		for(my $i=0;;$i++){
			my $ra_caller_info=[caller($i)];
			if(scalar(@$ra_caller_info)==0){last;}
			else{
				$caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
			}
		}
		$caller="CallerInfo:\n$caller";
		$err_detail="$_pkg_name\:\:$_str_func_select_col\(\) throw $_str_param_err\nHelpNote  : $_str_inline_null_err\n$sys_err$param$caller\n";
		if($_DEBUG&&!$once){
			if(defined($die_handler)){
				$die_handler->execute($err_code,$err_detail,$_pkg_name);
			}else{
				CORE::die $err_detail;
			}
		}	
		return wantarray?(undef,$err_code,$err_detail,$_pkg_name):undef;
	}

	my $unicode=$self->{unicode};
	my $dst_encoding=$self->{encoding} eq $_name_utf8?undef:$self->{encoding};
	if($unicode){_encode($sql_str,$bind_param,$dst_encoding);}
	my $sth = $self->{dbh}->prepare($sql_str);
	$succ = $sth->execute(@$bind_param);
    # save current sth error info 
    if($sth->err and !$self->is_connect()){
        $self->re_connect();
        $sth = $self->{dbh}->prepare($sql_str);
        $succ = $sth->execute(@$bind_param);
    }
    
	if(!$succ){
		my ($err_code,$err_detail,$die_handler)=(5,'',$self->{die_handler});
		my $sys_err=defined($sth->errstr)?"ErrString : ".$sth->errstr."\n":'';
		$sth->finish();
		my $param="ParamInfo :\n"._dump([$sql_str,@$bind_param])."\n";
		my $caller='';
		for(my $i=0;;$i++){
			my $ra_caller_info=[caller($i)];
			if(scalar(@$ra_caller_info)==0){last;}
			else{
				$caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
			}
		}
		$caller="CallerInfo:\n$caller";
		$err_detail="$_pkg_name\:\:$_str_func_select_col\(\) throw $_str_exec_err\nHelpNote  : $_str_dbh_execute_err\n$sys_err$param$caller\n";
		if($_DEBUG&&!$once){
			if(defined($die_handler)){
				$die_handler->execute($err_code,$err_detail,$_pkg_name);
			}else{
				CORE::die $err_detail;
			}
		}
		return wantarray?($succ,$err_code,$err_detail,$_pkg_name):$succ;
	}

	$succ=$sth->fetchall_arrayref([0]);
	if($sth->err){
		my ($err_code,$err_detail,$die_handler)=(5,'',$self->{die_handler});
		my $sys_err=defined($sth->errstr)?"ErrString : ".$sth->errstr."\n":'';
		$sth->finish();
		my $param="ParamInfo :\n"._dump([$sql_str,@$bind_param])."\n";
		my $caller='';
		for(my $i=0;;$i++){
			my $ra_caller_info=[caller($i)];
			if(scalar(@$ra_caller_info)==0){last;}
			else{
				$caller="\t$ra_caller_info->[1] LINE ".sprintf('%04s',$ra_caller_info->[2]).": $ra_caller_info->[3]\n$caller";
			}
		}
		$caller="CallerInfo:\n$caller";
		$err_detail="$_pkg_name\:\:$_str_func_select_col\(\) throw $_str_exec_err\nHelpNote  : $_str_dbh_fetchall_arrayref_err\n$sys_err$param$caller\n";
		if($_DEBUG&&!$once){
			if(defined($die_handler)){
				$die_handler->execute($err_code,$err_detail,$_pkg_name);
			}else{
				CORE::die $err_detail;
			}
		}
		return wantarray?(undef,$err_code,$err_detail,$_pkg_name):undef;
	}
	$sth->finish();
	for(my $i=scalar(@$succ);$i-->0;){
		$succ->[$i]=$succ->[$i]->[0];
	}
	if($unicode){_decode($succ,$dst_encoding);};
	return wantarray?($succ,0,undef,$_pkg_name):$succ;
}

sub repair_connection{
    my $self = shift;
    if(!$self->is_connect()){
        $self->re_connect();
    }
}

sub is_connect{
    my $self=shift;
    $self->{test_sth}=$self->{dbh}->prepare("select 1") unless($self->{test_sth});
    $self->{test_sth}->execute();
    my $flag = 0;
    $flag++ unless($self->{test_sth}->err);
    $self->{test_sth}->finish();
    return $flag;
}

sub re_connect{
    my $self=shift;
    $self->{dbh}->disconnect();
    undef $self->{dbh};
    my $dbh = DBI->connect(@{$self->{conn}});
    CORE::die defined(&DBI::errstr)?"ErrString : ".&DBI::errstr."\n":'' unless(defined $dbh);
    $self->{dbh} = $dbh;
    undef $self->{test_sth};
}

1;
__END__
