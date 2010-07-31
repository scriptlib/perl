package MyPlace::Baidu::Search;
#use MyPlace::HTTPGet;
use LWP::UserAgent;
my $HTTP;
use Encode;
use utf8;
my $_utf8 = find_encoding('utf8');
my $_gb = find_encoding('gb2312');

my %URLS = 
(
    image=>'http://image.baidu.com/i',
    www=>'http://www.baidu.com/s',
);

my %DEFAULT_PARAMS =
(
    www=>
    {
        wd=>'',
    },
    image =>
    {
        ct=>'201326592',
        tn=>'baiduimage',
        lm=>'-1',
        cl=>'2',
        word=>'',
        z=>'0',   
            #0=all,3=large,2=medium,1=small
            #4=800x600,5=1024x768,6=1280x960
            #8=1600x1200,19=wide,7=1280x1024
        tp=>'img',
            #imgnews=news images
            #img=images
        lmm=>'-1',
            #-1=所有格式,1=gif,2=bmp,3=jpg,4=png
#        ic=>'0',
            #0=所有颜色l,512=黑,1024=白,2048=黑白
            #1=红,2=黄,4=绿,8=青,16=蓝,32=紫,64=粉,128=棕,256=橙
#        site=>'',
#        size=>'1024_768',
    }

);

my %IMAGE_TYPE_MAP = 
(
    'all'=>'0',
    'large'=>'3',
    'medium'=>'2',
    'small'=>'1',
    '800x600'=>'4',
    '1024x768'=>'5',
    '1280x960'=>'6',
    '1280x1024'=>'7',
    '1600x1200'=>'8',
    'wide'=>'19',
);

sub new_image_url {
    my($url,$size,$width,$height) = @_;
    return {url=>$url,size=>$size,width=>$width,height=>$height};
}
sub build_image_url {
    my($base,$query,$page,$params) = @_;
    my %url_params = %{$DEFAULT_PARAMS{image}};
    while(my($key,$value) = each(%{$params}))
    {
        if($key eq 'type') {
            if($value and $IMAGE_TYPE_MAP{$value}) {
                $url_params{'z'} = $IMAGE_TYPE_MAP{$value};
            }
        }
        else {
            $url_params{$key} = $value;
        }
    }
    $url_params{word}=$query unless($url_params{word});
    if($page and $page =~ m/^[0-9]+$/ and $page>1 and (!$url_params{pn})) 
    {
        $url_params{pn}=($page - 1) * 21;
    }
    return &build_url($base,\%url_params);
}


sub build_url {
    my($base,$params) = @_;
    my @params;
#    my $url = URI->new($base);
#    $url->query_form(%{$params});
#    return $url;
    while(my($key,$value) = each %{$params}) {
        push @params,"$key=$value";
    }
    return $base . '?' . join('&',@params); 
}

use URI::Escape;
sub search_images 
{
    my($query,$page,%params)= @_;
    $query =uri_escape($_gb->encode($_utf8->decode($query)),'^\-_~\"\+a-zA-z0-9');
    my $search_url = build_image_url($URLS{image},$query,$page,\%params);
    if(!$HTTP) {
        $HTTP = LWP::UserAgent->new();
        $HTTP->agent("Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.3) Gecko/2008092416 Firefox/3.0.3 Firefox/3.0.1");
    }
    print STDERR "Retrieving $search_url ...";
    my $res = $HTTP->get($search_url,referer=>$search_url);
    print STDERR " [",$res->code,"]\n";
    unless($res->is_success) 
    {
        return undef,"error : " . $res->code . " " . $res->$status_line . "\n";
    }
    my $html = $_gb->decode($res->content);
    my @images;
    while($html =~ m/"objURL":"([^"]+?)\s*",.+?"width":(\d+),"height":(\d+),.+?"filesize":"(\d+)"/gs) {
        push @images,new_image_url($1,$2,$3,"$4k");
#    while($html =~ m/<img .+?(\d+)x(\d+)\s*(\d+[kmbgKMBG])\s*.+?\s*,\s*u:'([^']+)'/gs) {
#        push @images,new_image_url($4,$3,$1,$2);
    }
    return 1,\@images;
}

1;
