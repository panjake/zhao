package zhaoapi;
use Dancer ':syntax';
use strict;
use warnings;
use Cwd;
use Dancer::Plugin::DBIC;
use Sys::Hostname;
use zhaoapi::API::Click;
use zhaoapi::API::Click2;
use zhaoapi::Schema;
use zhaoapi::Manager::Report;
use zhaoapi::Manager;

use utf8;
use zhaoapi::Common::MD5;
use Storable qw( dclone );
use DateTime;
use URI;
use URI::Escape qw/uri_escape/;


our $VERSION = '0.1';

get '/' => sub {
    template 'index1';
};

get '/deploy' => sub {
    template 'deployment_wizard', {
		directory => getcwd(),
		hostname  => hostname(),
		proxy_port=> 8000,
		cgi_type  => "fast",
		fast_static_files => 1,
	};
};

#The user clicked "updated", generate new Apache/lighttpd/nginx stubs
post '/deploy' => sub {
    my $project_dir = param('input_project_directory') || "";
    my $hostname = param('input_hostname') || "" ;
    my $proxy_port = param('input_proxy_port') || "";
    my $cgi_type = param('input_cgi_type') || "fast";
    my $fast_static_files = param('input_fast_static_files') || 0;

    template 'deployment_wizard', {
		directory => $project_dir,
		hostname  => $hostname,
		proxy_port=> $proxy_port,
		cgi_type  => $cgi_type,
		fast_static_files => $fast_static_files,
	};
};



any '/sdk/list' => sub {
	set serializer => 'JSON';

	use Storable qw( dclone );

	my $param = dclone request->params;
    my $taintd = delete $param->{sign};
    my $sign = new zhaoapi::Common::MD5({ key => '22222222' });

    unless($taintd and $taintd eq $sign->md5digest( $param ) ){
        return  {
	        		'status' => 0,
		            'title'   => '',
		            'currency' => '',
		            'ts'		=> time,
		            'item'  => [],
	        	};
    }

	my $has_action = {};
	my $items = [];
	my $publisher = schema->resultset('Publisher')->search({
 			publisher_id => 1,
 		})->first;
 	#my $publisher_margin = $publisher->exchange * 100;


	my $promotion = schema->resultset('Promotion')->search({
 			status => 1,
 		});


	my $actions = schema->resultset('Action')->search({
 			user_id => 1,
 			publisher_id => 1,
 		});

	while (my $action = $actions->next) {
		$has_action->{$action->promotion_id} = 1;
	}

	while(my $item = $promotion->next ){
		my $status = 1;
		if(exists $has_action->{$item->id}){
			$status = 2;
		}
		my $package_name = $item->package_name || '';
		my $check = 0;
		if($package_name ne ''){
		   $check = 1;
		}
		my $point = $publisher->exchange * $item->expenses || 0;
		my $jump = request->uri_base."/sdk/click?promotion_id=".$item->id."&publisher_id=".$publisher->id;
		#$jump = uri_escape($jump);
		
		push @$items, {
			promotionId => $item->id,
			earnings => $item->earnings,
			expenses => $item->expenses,
			status	 => $status,
			icon	 => $item->icon,
			name	 => $item->name,
			identifier	 => $package_name,
			check	 => $check,
			point	 => $point,
			conditions	 => $item->conditions,
			detail		=> '',
			jumpUrl		=> $jump,
		};
	}

	$promotion->reset;
	my $now = DateTime->today( time_zone => 'Asia/Shanghai' );
	while (my $item = $promotion->next ) {
		my $report = schema->resultset('ReportOfAction')->find_or_create({
            date          => $now,
            promotion_id  => $item->id,
            publisher_id  => $param->{publisher_id},
		});

		$report->update({
			view => \'view + 1',
		});
	}

    my $json = {'status' => 1,
            'title'   => ($publisher->sdk_title || ''),
            'currency' => ($publisher->currency || ''),
            'ts'		=> time,
            'item'  => $items,
        };

   	if(exists $param->{web} and $param->{web}){
   		set layout=> 'wall_layout';
   		template 'wall', {
   			data => $json,
   		};

   	}else{
   		return $json;
   	}

    
};


any '/sdk/point' => sub {
	my $param = dclone request->params;
    my $taintd = delete $param->{sign};
    my $sign = new zhaoapi::Common::MD5({ key => '22222222' });

    unless($taintd and $taintd eq $sign->md5digest( $param ) ){
        return  {
	        		'status' => -9,
		            'ts' 	 => 13413411, 
		            'point'  => 0,
	        	};
    }


	my $reduce = param('reduce');

	my $user_point = schema->resultset('UserPoint')->search({
        publisher_id    => 1,
        user_id  => 1,
    })->first;

	unless($user_point){
		return {'status' => 0, 'ts' => 13413411, 'point' => 0};

	}

	if($reduce){
		my $point = $user_point->point - $reduce;
		if($point >= 0){
			$user_point->point($point);
			$user_point->update;

			return {'status'=> 1, 'ts'=>13413411, 'point'=>$point};
		}
		else{
			return {'status'=> -1, 'ts'=>13413411, 'point'=>0};
		}
	}
	else{
		return {'status'=>1, 'ts'=>13413411, 'point'=>$user_point->point};
	}

};


any '/sdk/send_action' => sub {
	set serializer => 'JSON';

	my $param = dclone request->params;
    my $taintd = delete $param->{sign};
    my $sign = new zhaoapi::Common::MD5({ key => '22222222' });

    unless($taintd and $taintd eq $sign->md5digest( $param ) ){
        return {'status'=> 0, 'msg'=>'sign wrong' };
    }


	unless( $param->{promotion_id} and $param->{publisher_id} ){
		return {'status' => 0, 'msg' => 'lost_params'}; 
	}

    ### 拿到活动信息
	my $promotion = schema->resultset('Promotion')->find($param->{promotion_id});

	##  拿到媒体信息
	my $publisher = schema->resultset('Publisher')->find($param->{publisher_id});
 	#my $publisher_margin = $publisher->exchange * 100;

	my $point = $promotion->expenses * $publisher->exchange || 0;

	my $action = schema->resultset('Action')->search({
			user_id => 1,
			promotion_id => $param->{promotion_id},
		})->first;

	if($action){
		return {'status' => -1, 'msg' => 'has action'};
	}

	my $t_earnings = $promotion->earnings;
	my $t_expenses = $promotion->expenses;


	schema->resultset('Action')->create({
            achieve_id    => \'uuid()',
            date          => \'CURDATE()',
            user_id       => 1,
            promotion_id  => $param->{promotion_id},
            publisher_id  => $param->{publisher_id},
            create_time   => \'NOW()',
			earnings   	  => $t_earnings,
	        expenses   	  => $t_expenses,
		});

	my $now = DateTime->today( time_zone => 'Asia/Shanghai' );

	my $report = schema->resultset('ReportOfAction')->find_or_create({
            date          => $now,
            promotion_id  => $param->{promotion_id},
            publisher_id  => $param->{publisher_id},
		});

	$report->update({
			achieve => \'achieve + 1',
			earnings => \"earnings + $t_earnings",
			expenses => \"expenses + $t_expenses",
		});

	my $user_point  = schema->resultset('UserPoint')->find_or_create({
            publisher_id    => 1,
    		user_id  => 1,
		});

	$point = $user_point->point + $point;

	$user_point->point($point);
	$user_point->update;

	return {'status' => 1, 'msg' => 'successed'};

};


any '/sdk/action' => sub {
	my $param = dclone request->params;


	if($param->{clear}){
		schema->resultset('Action')->search({})->delete;
		return {'status' => 1, 'msg' => 'deleted'};
	}

	unless( $param->{promotion_id} and $param->{publisher_id} ){
		return {'status' => 0, 'msg' => 'lost_params'}; 
	}

	### 拿到活动信息
	my $promotion = schema->resultset('Promotion')->find($param->{promotion_id});

	##  拿到媒体信息
	my $publisher = schema->resultset('Publisher')->find($param->{publisher_id});
 	#my $publisher_margin = $publisher->exchange * 100;

	my $point = $promotion->expenses * $publisher->exchange || 0;

	
	if( $promotion ){
		my $action = schema->resultset('Action')->search({
				user_id => 1,
				promotion_id => $param->{promotion_id},
			})->first;

		if($action){
			return {'status' => 0, 'msg' => 'has action'};
		}

		my $t_earnings = $promotion->earnings;
		my $t_expenses = $promotion->expenses;


		schema->resultset('Action')->create({
	            achieve_id    => \'uuid()',
	            date          => \'CURDATE()',
	            user_id       => 1,
	            promotion_id  => $param->{promotion_id},
	            publisher_id  => $param->{publisher_id},
	            create_time   => \'NOW()',
	            earnings   	  => $t_earnings,
	            expenses   	  => $t_expenses,
			});


		my $now = DateTime->today( time_zone => 'Asia/Shanghai' );

		my $report = schema->resultset('ReportOfAction')->find_or_create({
	            date          => $now,
	            promotion_id  => $param->{promotion_id},
	            publisher_id  => $param->{publisher_id},
			});

		$report->update({
				achieve => \'achieve + 1',
				earnings => \"earnings + $t_earnings",
				expenses => \"expenses + $t_expenses",
			});


		my $user_point  = schema->resultset('UserPoint')->find_or_create({
	            publisher_id  => 1,
        		user_id  => 1,
			});

		$point = $user_point->point + $point;

		$user_point->point($point);
		$user_point->update;

		return {'status' => 1, 'msg' => 'successed'};
	}
	else{
		return {'status' => 0, 'msg' => 'promotion not found'};
	}

};


any '/sdk/click' => sub {
	my $param = dclone request->params;

	unless( $param->{promotion_id} and $param->{publisher_id} ){
		return {'status' => 0, 'msg' => 'lost_params'}; 
	}

	my $promotion = schema->resultset('Promotion')->find($param->{promotion_id});

	my $location = $promotion->location;

	my $now = DateTime->today( time_zone => 'Asia/Shanghai' );

	my $report = schema->resultset('ReportOfAction')->find_or_create({
            date          => $now,
            promotion_id  => $param->{promotion_id},
            publisher_id  => $param->{publisher_id},
		});

	$report->update({
			click => \'click + 1',
		});

	redirect  $location;
};


true;
