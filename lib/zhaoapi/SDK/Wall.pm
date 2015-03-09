package zhaoapi::SDK::Wall;
use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use strict;
use warnings;
use Data::Dump qw/dump/;
use zhaoapi::Schema;
use zhaoapi::Common::Tools;
use Try::Tiny;
use zhaoapi::Common::MD5;
use Storable qw( dclone );
set serializer => 'JSON';

use parent qw(zhaoapi::SDK);


before sub{
    my $response = shift;
    
};

get '/sdk/list' => sub {
    my $response = session('response');
    if($response){
      return $response;
    }


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

#############################################
# http://0.0.0.0:3000/api/confirm?promotion_id=1101&mac=&idfa=B219B8B6-C06D-4DEA-9814-F9B8D1190EC2&sign=xxx
#
#
get '/sdk/point' => sub {
    my $response = session('response');
    if($response){
        return $response;
    }

    my $user = session('user');
    unless($user){
        return  {'success'=>0, 'msg'=>'Media not found.'};
    }

    # check
    my $campaign = session('campaign');
    unless( $campaign->is_available ){
        return  {'success'=>0, 'msg'=>'promotion is not available.'};
    }

    ## check sign
    unless(request->address =~ /^211\.151\.17\.36$/ 
        or request->address =~ /^222\.73\.96\.250$/
        or request->address =~ /^127\.0\.0\.1$/){
        my $sign = new zhaoapi::Common::MD5({ key => $campaign->key });

        my $param = dclone request->params;
        my $taintd = delete $param->{sign};

        unless($taintd and $taintd eq $sign->md5digest( $param ) ){
            return  {'success'=>0, 'msg'=>'sign lost or not match.'};
        }
    }
    
    my $achieve = $campaign->search_related('achieves', {
        user_id       => $user->id,
    })->single;

    unless($achieve){
        $achieve = $campaign->create_related('achieves', {
            achieve_id    => \'uuid()',
            date          => \'CURDATE()',
            user_agent    => (request->user_agent || ''),
            ip            => (request->address || 'unknow'),
            user_id       => $user->id,
            campaign_id   => $campaign->id,
            create_time   => \'NOW()',
        });

        $achieve = $campaign->search_related('achieves', {
            user_id       => $user->id,
        })->single;
    }

    unless ( defined $achieve->is_accepted ) {
        my $click = $user->click_of_campaign( $campaign );

        if($click){
            $achieve->click_id( $click->click_id );
            my $rand_number = int(rand(100)+1);
            if($rand_number >=1 and $rand_number <= 16){
                $achieve->media_id( 1 );
            }
            else{
                $achieve->media_id( $click->media_id );
            }

            my $txn = sub {
                my $offer = $campaign->price_a;
                my $commission = $campaign->price_b;

                my $ss = schema->resultset('Campaign')->search( {
                    "spending + $offer" => { '<=' => $campaign->budget }
                  } )->first;

                my $new_spending = $ss->spending + $offer;
                
                my $rv = $ss->update({
                    spending => $new_spending,
                });
                # if no rows were affected, then update returns "0E0"
                
                ##modify by pan.wujie 2012-01-22##
                if ( $rv > 0 ) {
                    $achieve->earnings( $offer );
                    $achieve->expenses( $commission );
                    $achieve->is_accepted(1);
                    $achieve->accepted_time(\'NOW()');
                }
                else {
                    $achieve->is_accepted(0);
                    $achieve->accepted_time(\'NOW()');
                }
                $achieve->update;
            };

            try {
              schema->txn_do( $txn );
            }
            catch {
              ## warn
              warn $_;
            };
        }else{
            $achieve->is_accepted(0);
            $achieve->accepted_time(\'NOW()');
            $achieve->update;
        }
    }
    else{
      return  {'success'=>1, 'msg'=>'repeatedly.'};
    }

    return  {'success'=>1, 'msg'=>'successed.'};
};


true;
