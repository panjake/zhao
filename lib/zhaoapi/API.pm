package zhaoapi::API;
use Dancer ':syntax';
use strict;
use warnings;
use Dancer::Plugin::DBIC;
use zhaoapi::Schema;
set serializer => 'JSON';


# find or create user
before sub{
	my $idfa = param('idfa');
	my $mac  = param('mac');
	if($mac){
		$mac = lc($mac);
		$mac =~ s/://g;
	}

	if( ( $idfa and $idfa =~ /^[\w-]+$/ ) 
		or ( $mac and $mac =~ /^[a-z0-9A-Z]{12}$/ ) ){
		
		my $user;
		if($idfa){
			$user = schema->resultset('User')->search({identifier => $idfa})->first;
		}
		
		unless($user){
			if ( $mac and $mac =~ /^[a-z0-9A-Z]{12}$/ ) {
				$user = schema->resultset('User')->search({identifier2 => $mac})->first;
			}
		}

		unless ($user) {
			$user = schema->resultset('User')->create({
					identifier 	=> $idfa,
					identifier2	=> $mac,
				});
		}
		session user => $user;
	}else{
		session response => {'success'=>0, 'msg'=>'idfa or mac not format or lost.'};
        return;
	}

	my $promotion_id = param('promotion_id');
    if( $promotion_id and $promotion_id =~ /^\d+$/ ){
      my $campaign = schema->resultset('Campaign')->find( $promotion_id );
      if($campaign){
        session campaign => $campaign;
      }else{
        session response => {'success'=>0, 'msg'=>'promotion not fouch or has been expired.'};
        return;
      }
    }else{
        session response => {'success'=>0, 'msg'=>'promotion_id not format or lost.'};
        return;
    }

};


true;