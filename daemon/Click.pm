package daemon::Click;

use FindBin qw( $Bin );
use lib "$Bin/../daemon";
use Moose;
use namespace::autoclean;
use URI;
use HTTP::Request::Common qw/POST/;
use URI::QueryParam;
use Digest::MD5 qw/md5_hex/;
use Digest::SHA qw/sha1_hex/;
use URI::Escape qw/uri_escape/;
use Data::Dump qw/dump/;
use JSON;
use Framework::EasyTool;
use LWP::UserAgent;
use daemon::DB;
use utf8;


has 'ua' => (
  is => 'ro',
  isa => 'LWP::UserAgent',
  lazy_build => 1,
);



# Arguments:
# Return Value: $rs
sub callback_confirm {
    my $self = shift;

    my $dba = new daemon::DB;

    my $callback_confirm = $dba->select("
        select 
          *
        from queue_forward_click 
        where forward_time <= now() and attempted < 3 
        order by forward_time
        limit 0,100
    ");

    return $callback_confirm;

}

# Arguments: $row: CallbackConfirm
# Return Value:
sub forward {
  my ( $self, $callback_confirm ) = @_;
  
  my ( $click, $res, $content );
  my $uri;

  my $dba = new daemon::DB;

  if ( $callback_confirm ) {
        my $click_id = $callback_confirm->{id};
        
        $click = $dba->select_row("
            select
                cc.id click_id,
                s1.name site_name,
                u.identifier user_identifier,
                u.tracking1 idfa,
                u.tracking2 mac,
                u.tracking3 openudid,
                cc.ip,
                cc.media_identifier identifier,
                cc.date,
                cc.campaign_id,
                cc.media_id,
                c.click_notify_url confirm_url
            from click cc
            join user u on u.id = cc.user_id
            join campaign c on cc.campaign_id = c.id
            join site s1 on c.site_id = s1.id 
            where cc.id = ?
            limit 1
          ",[$click_id]);
    }

  if ( $click ) {
  	# TODO make a FactoryModel for both REQ AND RES
    $uri = $self->uri_to_forward( $click );
    $res = $self->ua->get( $uri->as_string );      
  	chomp( $content = $res->content );
  }
  
  my $response;  
  if ( $res && $res->is_success && defined $content ) {
      eval{
        $response = from_json($content);
      };

      if($@){
        #warn $@;
      }
      
      $self->_forwarded($dba, $callback_confirm, $content);

      # if( exists $response->{'success'} and ($response->{'success'} == 1 or $response->{'success'} eq 'true' or (exists $response->{'code'} and $response->{'code'} eq '1') ) ){
      #   $self->_forwarded($dba, $callback_confirm, $content);
      # }else{
      #   $self->_defer($dba, $callback_confirm, $content);
      #   ## 
      #   if(defined $content){
      #     warn  $content;
      #   }
      #   ##log##
      # }
  }
  ## failed ##
  else {  
    $self->_defer( $dba, $callback_confirm, $content );
    ###log##
    if(defined $content){
        $dba->execute("delete from queue_forward_click where click_id = ? ",[$callback_confirm->{click_id}]);
    }
    ##log##
  }
}

sub _forwarded {
    my ( $self, $dba, $callback_confirm ) = @_;

    $dba->execute("delete from queue_forward_click where click_id = ? ",[$callback_confirm->{click_id}]);
}


sub _defer {
    my ( $self, $dba, $callback_confirm, $message ) = @_;
    
    my $minute = 2 ** $callback_confirm->{attempted};

    my $sql_part = '';
    if ( defined $message ) {
      $message = substr($message,0,50);
      $sql_part .= " ,message = '".$message."' ";
    }
    
    $dba->execute("
        update queue_forward_click 
          set attempted = attempted + 1, 
          forward_time = DATE_ADD( NOW(), INTERVAL $minute MINUTE )  
          $sql_part 
        where click_id = ? 
      ",[$callback_confirm->{click_id}]);
}



# Arguments: $row: Media, $hash
# Return Value: $object: URI
sub uri_to_forward {
  my ( $self, $click ) = @_;
  my $uinfo = "";
  my $param = {};
   ## get callback uri ###
  my $uri = new URI( $click->{confirm_url} );

  if( $uri =~ /\[/ and $uri =~ /\]/  ){	  
  my $url = replace_url( $uri, $click );
    return new URI( $url );
  }
  else{
      $param = {
        adid        => $click->{campaign_id},
        identifier  => $click->{identifier},
      };
            
      $param->{'mac'}  = $click->{mac}  || '';
      $param->{'idfa'} = $click->{idfa} || '';
  }
  
  ###build uri with params#  
  $uri->query_param_append( $_, $param->{ $_ } ) foreach keys %$param;
  return $uri;
}

sub replace_url{
  my ( $url, $click ) = @_;

  ###########deal uinfo###
  my $id1 = $click->{user_identifier}  || ""; #mac or idfa
  my $id2 = $click->{tracking2} || ""; #mac
  my $id3 = $click->{tracking1} || ""; #idfa

  my $mac_up = uc($id2);##大写
  my $last_update = $click->{last_update};
  my $media_id = $click->{media_id};
  my $campaign_id = $click->{campaign_id};
  my $click_id = $click->{click_id};
  my $ip = $click->{ip};
  my $mao_mac_up ='';
  if( $mac_up ne '' ){
      map{ $mao_mac_up .= (substr($mac_up,$_,2).":") if($_%2 ==0 && $_ != 11)} (0..11);
      chop($mao_mac_up);
  }

  my $idfa_no_line = $id3;
  if($idfa_no_line ne ''){
      $idfa_no_line =~ s/-//ig;
  }
  
  if( $id2 eq '' ){
      my $ios7_mac = '020000000000'; 
      my $ios7_mac_mao = '02:00:00:00:00:00';
      $url =~ s/\[MAC_IOS7\]/$ios7_mac/ig;
      $url =~ s/\[MAC_IOS7_UP\]/$ios7_mac/ig;
      $url =~ s/\[MAC_IOS7_MAO\]/$ios7_mac_mao/ig;
  }
  
  
  ### 选择性发送 针对 惟千
  if( $url =~ /\[CHOOSE\]/i or $url =~ /\[CHOOSE_MAO_UP\]/i or $url =~ /\[CHOOSE_UP\]/i){
      if( $id2 eq '' ){
          $url =~ s/\[TYPE\]/idfa/i;
          $url =~ s/\[CHOOSE\]/$id3/i;
          $url =~ s/\[CHOOSE_MAO_UP\]/$id3/i;
		  $url =~ s/\[CHOOSE_UP\]/$id3/i;
      }
      else{
          $url =~ s/\[TYPE\]/mac/i;
          $url =~ s/\[CHOOSE\]/$id2/i;
          $url =~ s/\[CHOOSE_MAO_UP\]/$mao_mac_up/i;
		  $url =~ s/\[CHOOSE_UP\]/$mac_up/i;
      }
  }
  
  ### 有idfa传idfa， 没有则传mac
  if( $url =~ /\[CHOOSE_IDFA\]/i or $url =~ /\[CHOOSE_IDFA_MAO_UP\]/i or $url =~ /\[CHOOSE_IDFA_UP\]/i){
      if( $id3 eq '' ){
          $url =~ s/\[CHOOSE_IDFA\]/$id2/i;
          $url =~ s/\[CHOOSE_IDFA_MAO_UP\]/$mao_mac_up/i;
		  $url =~ s/\[CHOOSE_IDFA_UP\]/$mac_up/i;
      }
      else{
          $url =~ s/\[CHOOSE_IDFA\]/$id3/i;
          $url =~ s/\[CHOOSE_IDFA_MAO_UP\]/$id3/i;
		  $url =~ s/\[CHOOSE_IDFA_UP\]/$id3/i;
      }
  }
  
  ### for ios7  add a default value
  $url =~ s/\[MAC_IOS7\]/$id2/ig;
  $url =~ s/\[MAC_IOS7_UP\]/$mac_up/ig;
  $url =~ s/\[MAC_IOS7_MAO\]/$mao_mac_up/ig;

  $url =~ s/\[MAC\]/$id2/ig;
  $url =~ s/\[MAC_UP\]/$mac_up/ig;
  $url =~ s/\[MAO_MAC_UP\]/$mao_mac_up/ig;
  $url =~ s/\[UDID\]/$id1/ig;
  $url =~ s/\[IDFA\]/$id3/ig;
  $url =~ s/\[IDFA_NO_LINE\]/$idfa_no_line/ig;
  $url =~ s/\[MEDIA_ID\]/$media_id/ig;
  $url =~ s/\[CAMPAIGN_ID\]/$campaign_id/ig;
  $url =~ s/\[IP\]/$ip/ig;
  $url =~ s/\[DATE\]/$last_update/ig;
  my $timestamp = EasyTool::time_2_timestamp($last_update);
  $url =~ s/\[TIMESTAMP\]/$timestamp/ig;
  $url =~ s/\[CLICK_ID\]/$click_id/ig;

  # if( $url =~ /\[CONFIRM_URL\]/i ){
  #   	my $confirm_url = get_confirm_url($click);
  #   	$confirm_url = uri_escape($confirm_url);
    	
  #   	$url =~ s/\[CONFIRM_URL\]/$confirm_url/ig;
  # }
  return $url;
}

sub _build_ua {
  my $ua = new LWP::UserAgent;
  return $ua;
}





__PACKAGE__->meta->make_immutable;
