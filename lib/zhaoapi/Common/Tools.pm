package zhaoapi::Common::Tools;

use Moose;
use namespace::autoclean;
use URI;
use HTTP::Request::Common qw/POST/;
use URI::QueryParam;
use Digest::MD5 qw/md5_hex/;
use URI::Escape qw/uri_escape/;
use Data::Dump qw/dump/;
use JSON;


sub replace_url{
  my ($url, $campaign, $user, $click) = @_;

  my $campaign_id = $campaign->id;
  ###########deal uinfo###
  my $id3 = $user->identifier  || "";
  my $id2 = $user->identifier2 || "";

  my $mac_up = uc($id2);##大写
  my $last_update = $click->date;
  my $media_id = $click->media_id;
  my $click_id = $click->click_id;
  my $ip = $click->ip;
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
  $url =~ s/\[IDFA\]/$id3/ig;
  $url =~ s/\[IDFA_NO_LINE\]/$idfa_no_line/ig;
  $url =~ s/\[MEDIA_ID\]/$media_id/ig;
  $url =~ s/\[CAMPAIGN_ID\]/$campaign_id/ig;
  $url =~ s/\[IP\]/$ip/ig;
  $url =~ s/\[DATE\]/$last_update/ig;
  $url =~ s/\[CLICK_ID\]/$click_id/ig;

  if( $url =~ /\[CALLBACK\]/i ){
	my $confirm_url = get_confirm_url($campaign, $media_id, $user);
	$confirm_url = uri_escape($confirm_url);
	
	$url =~ s/\[CALLBACK\]/$confirm_url/ig;
  }

  return $url;
}

sub get_confirm_url{
  my ($campaign, $media_id, $user) = @_;
  
  my $confirm_url = "http://182.92.131.59:3000/";
  my $action = "api/confirm";
  $confirm_url .= $action;
  
  my $uri = new URI( $confirm_url );
  
  my $uinfo = $user->identifier2 || '';
  
  my $idfa = $user->identifier;
  
  my $param = {
    'promotion_id' => $campaign->campaign_id,
    'mac' => $uinfo,
    'idfa' => $idfa,
  };

  my @digest_params = sort keys %$param;
  my $param_sort = "";
  map{ $param_sort .= "$param->{$_}," } @digest_params;
  $param_sort .= $campaign->key;
  
  my $digest = md5_hex($param_sort);
  $param->{sign} = $digest;
  
  $uri->query_param_append( $_, $param->{ $_ } ) foreach keys %$param;
  return $uri;
}



__PACKAGE__->meta->make_immutable;






