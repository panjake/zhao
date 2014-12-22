package daemon::Achieve;

use FindBin qw( $Bin );
use lib "$Bin/../daemon";
use Moose;
use namespace::autoclean;
use URI;
use URI::QueryParam;
use Digest::MD5 qw/md5_hex/;
use URI::Escape;
use Data::Dump qw/dump/;
use URI::Escape qw/uri_escape uri_unescape/;
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
sub achieve_to_forward {
    my ($self) = @_;

    my $dba = new daemon::DB;

    my $achieve_to_forward = $dba->select("
        select 
          *
        from achieve_to_forward 
        where forward_time <= now() and attempted < 3 
        order by forward_time
        limit 0,50
      ");

    return $achieve_to_forward;
}


sub forward{
    my ( $self, $achieve_to_forward ) = @_;

    my $dba = new daemon::DB;


    my ( $achieve, $res, $content );
    my $uri;

    if ( $achieve_to_forward ) {
        my $uuid = $achieve_to_forward->{achieve_id};
        
        $achieve = $dba->select_row("
            select
                a.achieve_id,
                c.name site_name,
                u.identifier idfa,
                u.identifier2 mac,
                cc.ip,
                cc.identifier,
                a.accepted_time,
                a.campaign_id,
                a.media_id,
                m.callback
            from achieve  a
            join click cc on cc.click_id = a.click_id
            join user u on u.user_id = a.user_id
            join campaign c on a.campaign_id = c.campaign_id
            join media m on m.media_id = a.media_id
            where a.achieve_id = ?
            limit 1
          ",[$uuid]);
    }

    if ( $achieve and exists $achieve->{achieve_id} ) {
        my $param_to_forward = {
            uuid => $achieve->{uuid},
            identifier => ($achieve->{identifier} || ''),
            idfa       => ($achieve->{idfa} || ''),
            mac        => ($achieve->{mac} || ''),
        };

        $uri = $self->uri_to_forward( $param_to_forward, $achieve );
        $res = $self->ua->get( $uri->as_string );
        chomp( $content = $res->content );
    }

    if ( $res && $res->is_success && (_can_content_be_handled( $content ) or _can_content_be_handled_json( $content )) ) {
        $self->_forwarded( $dba, $achieve_to_forward, $content );
    }
    else {
        $self->_defer( $dba, $achieve_to_forward, $content );
    }


}


sub _forwarded {
    my ( $self, $dba, $achieve_to_forward, $is_forwarded ) = @_;

    eval {
        $dba->execute("
            update achieve 
              set is_forwarded = ?, 
              forwarded_time = now() 
            where achieve_id = ?
            ",[$is_forwarded, $achieve_to_forward->{achieve_id}]);

        $dba->execute("delete from achieve_to_forward where achieve_id = ? ",[$achieve_to_forward->{achieve_id}]);
    };
    if ($@) {
      warn $@;
    }
    

    # my $txn = sub {
    #   $self->achieve->update({
    #     is_forwarded => $is_forwarded,
    #     forward_time => \'NOW()',
    #   });
    #   $self->delete;
    # };
    # try {
    #   $self->result_source->schema->txn_do( $txn );
    # }
    # catch {
    #   warn $_;
    # }
}


sub _defer {
  my ( $self, $dba, $achieve_to_forward, $message ) = @_;
  
  my $minute = 2 ** $achieve_to_forward->{attempted};

  my $sql_part = '';
  if ( defined $message ) {
    $message = substr($message,0,50);
    $sql_part .= " ,message = '".$message."' ";
  }
  
  $dba->execute("
      update achieve_to_forward 
        set attempted = attempted + 1, 
        forward_time = DATE_ADD( NOW(), INTERVAL $minute MINUTE )  
        $sql_part 
      where achieve_id = ? 
    ",[$achieve_to_forward->{achieve_id}]);
}


sub uri_to_forward {
    my ( $self, $param, $achieve ) = @_;

    my $uri =  new URI( $achieve->{callback} );
    my $replace_flag = 0;


    if( $achieve->{media_id} == 21 ){# domob
        my $appid = $achieve->{identifier} || '';
        my $postback_url = 'http://e.domob.cn/track/ow/api/postback';
        my $appid_key = { 
                          582934943 => '5948a096364b5e31f900887878e0a8d8',
                       };
        my $mac =  $achieve->{mac} || '';
        my $idfa = $achieve->{idfa} || '';

        my $sign_param = {
            appId => $appid,
            udid => $mac,
            ifa => $idfa,
            oid => '',
        };

        my $str = "$sign_param->{appId},$sign_param->{udid},,$sign_param->{ifa},$sign_param->{oid},$appid_key->{$appid}"; #md5(appid,udid,ma,ifa,oid,key);
        $sign_param->{sign}  = md5_hex($str);

        $uri = new URI( $postback_url );
        $uri->query_param_append( $_, $sign_param->{ $_ } ) foreach keys %$sign_param;
    }
    ## common
    elsif( $uri ){
      my $appname = $achieve->{site_name} || "";
      my $campaign_id = $achieve->{campaign_id};

      $appname = uri_escape_utf8($appname);
      $uri =~ s/\[APPNAME\]/$appname/i;

      my $action_time = ( EasyTool::time_2_timestamp( $achieve->{accepted_time} ) );
      $uri =~ s/\[ACTION_TIME\]/$action_time/i;

      ###########deal uinfo###
      my $id1 = $achieve->{user_identifier}  || "";
      my $id2 = $achieve->{mac} || "";
      my $id3 = $achieve->{idfa} || "";
      my $ip = $achieve->{ip};

      my $mac_up = uc($id2);##大写
      my $mao_mac_up ='';
      if( $mac_up ne '' ){
          map{ $mao_mac_up .= (substr($mac_up,$_,2).":") if($_%2 ==0 && $_ != 11)} (0..11);
          chop($mao_mac_up);
      }
      
      if( $uri =~ /\[MAC_IOS7(.*)\]/ ){
          if( $id2 eq '' ){
              my $ios7_mac = '020000000000'; 
              my $ios7_mac_mao = '02:00:00:00:00:00';
              $uri =~ s/\[MAC_IOS7\]/$ios7_mac/ig;
              $uri =~ s/\[MAC_IOS7_UP\]/$ios7_mac/ig;
              $uri =~ s/\[MAC_IOS7_MAO\]/$ios7_mac_mao/ig;
              delete $param->{ mac };
          }
      }

      ### 选择性发送 针对 惟千
      if( $uri =~ /\[CHOOSE\]/i or $uri =~ /\[CHOOSE_MAO_UP\]/i){
          if( $id2 eq '' ){
              $uri =~ s/\[TYPE\]/idfa/i;
              $uri =~ s/\[CHOOSE\]/$id3/i;
              $uri =~ s/\[CHOOSE_MAO_UP\]/$id3/i;
          }
          else{
              $uri =~ s/\[TYPE\]/mac/i;
              $uri =~ s/\[CHOOSE\]/$id2/i;
              $uri =~ s/\[CHOOSE_MAO_UP\]/$mao_mac_up/i;
          }
          delete $param->{ mac };
          delete $param->{ idfa };
      }

      ### for ios7  add a default value
      if( $uri =~ /\[MAC_IOS7\]/ or $uri =~ /\[MAC_IOS7_UP\]/ or $uri =~ /\[MAC_IOS7_MAO\]/ 
        or $uri =~ /\[MAC\]/ or $uri =~ /\[MAC_UP\]/ or $uri =~ /\[MAO_MAC_UP\]/ ){
        ####
          $uri =~ s/\[MAC_IOS7\]/$id2/ig;
          $uri =~ s/\[MAC_IOS7_UP\]/$mac_up/ig;
          $uri =~ s/\[MAC_IOS7_MAO\]/$mao_mac_up/ig;

          $uri =~ s/\[MAC\]/$id2/ig;
          $uri =~ s/\[MAC_UP\]/$mac_up/ig;
          $uri =~ s/\[MAO_MAC_UP\]/$mao_mac_up/ig;

          delete $param->{ mac };
      }

      ### idfa
      if($uri =~ /\[IDENTIFIER\]/){
          $uri =~ s/\[IDENTIFIER\]/$param->{ identifier }/ig;
          delete $param->{ identifier };
      }

      ### ip
      $uri =~ s/\[IP\]/$ip/ig;

      ### PROMOTION_ID
      $uri =~ s/\[PROMOTION_ID\]/$achieve->{campaign_id}/ig;

      ### idfa
      if($uri =~ /\[IDFA\]/){
          $uri =~ s/\[IDFA\]/$id3/ig;
          delete $param->{ idfa };
      }

      
      if( $uri =~ /\[ACHIEVE_ID\]/ ){
          $uri =~ s/\[ACHIEVE_ID\]/$param->{achieve_id}/ig;
          delete $param->{ achieve_id };
      }

      if($uri =~ /\[CALLBACK_URL\]/i){
          $uri = $achieve->{identifier} || "";
          $uri = uri_unescape($uri);
          ### return
          $uri = new URI($uri);
          return $uri;
      }
       
      ###
      $uri = new URI($uri);
      ## common params ####
      $uri->query_param_append( $_, $param->{ $_ } ) foreach keys %$param;
    }
    
    return $uri;
}


# Arguments: $scalar
# Return Value: true|false
sub _can_content_be_handled {
  my $content = shift;
  
  return defined $content && ( $content eq '0' || $content eq '1' );
}

# Arguments: $scalar
# Return Value: true|false
sub _can_content_be_handled_json {
    my $content = shift;
    if(defined $content){
        if($content eq '0' || $content eq '1'){
            return 1;
        }
        elsif($content =~ /^{.*}$/){
             my $response = from_json($content);
             if( $response and ( exists $response->{'success'} or  exists $response->{'status'} ) ){
                my $status = $response->{'success'} || $response->{'status'};
                if($status eq '1' or $status eq 'true'){
                    return 1;
                }
             }
        }
    }
    
    return 0;
}

sub _build_ua {
  my $ua = new LWP::UserAgent;
  return $ua;
}



__PACKAGE__->meta->make_immutable;
