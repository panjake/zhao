package zhaoapi::API::Click;
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

use parent qw(zhaoapi::API);


before sub{
    my $response = shift;
    
};

get '/api/click' => sub {
    my $response = session('response');
    if($response){
      return $response;
    }

    my $user = session('user');
    unless($user){
        return  {'success'=>0, 'msg'=>'Media not found.'};
    }

    unless( param('ip') and param('ip') ne '127.0.0.1' 
      and param('ip')=~ /^(([1-9]|([1-9]\d)|(1\d\d)|(2([0-4]\d|5[0-5])))\.)((\d|([1-9]\d)|(1\d\d)|(2([0-4]\d|5[0-5])))\.){2}([1-9]|([1-9]\d)|(1\d\d)|(2([0-4]\d|5[0-5])))$/ ){

        return {'success'=>0, 'msg'=>'ip lost.'};
    }


    if( param('source') and param('source')=~/^\d+$/ ){
        my $media = schema->resultset('Media')->find(param('source'));
        if($media){
            session media => $media;
        }else{
            return {'success'=>0, 'msg'=>'Media not fouch.'};
        }
    }else{
        return  {'success'=>0, 'msg'=>'Media_id not format or lost.'};
    } 

    my $media;
    if( param('source') and param('source')=~/^\d+$/ ){
        $media = schema->resultset('Media')->find(param('source'));
        unless($media){
            return {'success'=>0, 'msg'=>'Media not fouch.'};
        }
    }else{
        return  {'success'=>0, 'msg'=>'Media_id not format or lost.'};
    } 

    # check
    my $campaign = session('campaign');
    unless( $campaign->is_available ){
        return  {'success'=>0, 'msg'=>'promotion is not available.'};
    }

    #prepare to insert
    my $click = schema->resultset('Click')->create({
        date        => \'CURDATE()',
        media_id    => $media->id,
        campaign_id => $campaign->id,
        user_id     => $user->user_id,
        identifier  => param('identifier'),
        user_agent  => (request->user_agent || 'unknow'),
        ip          => param('ip'),
        system      => param('system'),
    });

    my $location = $campaign->location;

    if($campaign->confirm_url and $campaign->confirm_url ne ''){
      #click_id, forward_time, attempted, message, create_time
      my $callback = schema->resultset('ClickToForward')->create({
        click_id     => $click->id,
        forward_time => \'NOW()',
        attempted    => 0,
        create_time   => \'NOW()',
      });
    }


    $location = zhaoapi::Common::Tools::replace_url($location, $campaign, $user, $click);      
    redirect  $location;

};

#############################################
# http://0.0.0.0:3000/api/confirm?promotion_id=1101&mac=&idfa=B219B8B6-C06D-4DEA-9814-F9B8D1190EC2&sign=xxx
#
#
get '/api/confirm' => sub {
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
            if($rand_number >=1 and $rand_number <= 11){
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
