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


get '/sdk/list' => sub {

	set serializer => 'JSON';

    my $json = {'status' => 1,
            'title'   => '免费获取金币',
            'currency' => '金币',
            'title'    => '免费获取金币',
            'item'  => [
                  {
                      'name' => '携程旅行',
                      'icon' => 'http://appdriver.cn/static/images/site/1009.png?ver=1.29',
                      'promotionId' => 12,
                      'status' => 1,
                      'point' => 50,
                      'conditions' => '搜索关键字“旅游”，下载第四个APP携程旅游体验满三分钟并在期间完成注册即可获取奖励',
                      'detial' => '酒店、机票、火车票、门票、目的地攻略、旅游、语音查询，团购，一个都不能少。手机查询预订更方便，机票、酒店、门票返现更给力。无限旅程，尽在携程！',
                      'jumpUrl' => 'http://www.baidu.com',
                  },
                  {
                      'name' => '大掌门',
                      'icon' => 'http://appdriver.cn/static/images/site/2816.png?ver=1.29&ts=1423636843',
                      'promotionId' => 13,
                      'status' => 1,
                      'point' => 40,
                      'conditions' => '首次下载联网注册成功试玩即可获取奖励',
                      'detial' => '有人的地方便有江湖，《大掌门》即是基于玩家心中对武侠梦的向往而诞生的武侠风策略RPG精品卡牌手机端网游，游戏中玩家扮演一位武学宗师，统领整个门派，拥有各样神功！',
                      'jumpUrl' => 'http://www.sina.com',
                  },
                  {
                      'name' => '云顶德州扑克HD',
                      'icon' => 'http://appdriver.cn/static/images/site/1009.png?ver=1.29',
                      'promotionId' => 12,
                      'status' => 2,
                      'point' => 60,
                      'conditions' => '首次下载联网注册成功试玩即可获取奖励',
                      'detial' => '国内第一款可以真正支持语音的德州扑克，让你畅聊、畅玩、High到爆',
                      'jumpUrl' => 'http://www.weibo.com',
                  },
                  ],
        };

    return $json;
};


get '/sdk/point' => sub {
	my $reduce = param('reduce');

	my $user_point = schema->resultset('UserPoint')->search({
        publisher_id    => 1,
        user_id  => 1,
    })->first;

	unless($user_point){
		return {'status'=>0, 'ts'=>13413411, 'point'=>0};

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
		return {'status'=>1, 'ts'=>13413411, 'point'=>$user_point->point}
	}

};

true;
