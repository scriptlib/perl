package MyPlace::Discuz;
use strict;
use lib $ENV{XR_PERL_MODULE_DIR};
use HTML::TreeBuilder;
use LWP::UserAgent;
use HTTP::Cookies;
use URI;
use Encode qw/decode/;
use MyPlace::HTML::Convertor;
use MyPlace::Cache;

my $ua;
my $cookie;
my %login_try;
my $cache = MyPlace::Cache->new("httpget");

sub new {
    my $class=shift;
    return bless{@_} ,$class;
}


sub get_url {
    my ($ua,$url) = @_;
    return $ua->request(HTTP::Request->new(GET=>$url));
}

sub http_get {
    my($self,$url,$user,$pass,$try) = @_;
    return (undef,"Invalid url\n") unless($url);
    if($url =~ /\?/) {
        $url = "$url&adult=agreed" unless($url =~ /adult=agreed/);
    }
    my @cached = $cache->load($url);
    return (1,@cached) if(@cached);
    $user ||= $self->{user};
    $pass ||= $self->{pass};
    unless($ua) {
        $ua = LWP::UserAgent->new;
        $cookie = HTTP::Cookies->new(file => "$ENV{'HOME'}/.discuz_cookies.dat", autosave => 1);
        $ua->cookie_jar($cookie);
        $ua->agent("Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.3) Gecko/2008092416 Firefox/3.0.3 Firefox/3.0.1");
    }
    $try = 6 unless($try);
    my $req = HTTP::Request->new(GET => $url);
    my $res = $ua->request($req);
    if($res->is_success) {
        my($state,$login,%posts) = _parse_res_content($res->content);        
        if($state and $state == 1 and $login) {
            $login_try{$url} =  $login_try{$url} ? $login_try{$url}+1 : 1;
            if($login_try{$url}>4) {
                return (undef,"Stop trying to login $url,check your username and password\n");
            }
            print STDERR "Try to login first\n";
            $login = URI->new_abs($login,$url);
            $posts{username}=$user;
            $posts{password}=$pass;
            $posts{referer}=$url;
            my $post="" ; #= "username=$user&password=$pass";
            foreach(keys %posts) {
                $post = $post . "&$_=" . $posts{$_};
            }
            $post = substr($post,1);
            print STDERR "Posting:$post\n";
            $req = HTTP::Request->new(POST=>$login);
            $req->header(referer=>$url);
            $req->content_type('application/x-www-form-urlencoded');
            $req->content($post);
            $res = $ua->request($req);
            if($res->is_success) {
                @_ = ($self,$url,$user,$pass);
                sleep 3;
                goto &http_get;
            }
            else {
                $try--;
                if($try>0) {
                    print STDERR $res->status_line," ($try)Try again...\n";
                    @_ = ($self,$url,$user,$pass,$try);
                    sleep 3;
                    goto &http_get;
                }
                else {
                    return (undef,$res->status_line);
                }
            }
        }
        elsif($state == 2) {
                $try--;
                if($try>0) {
                    print STDERR "\n",$res->status_line," ($try)Reloading...";
                    @_ = ($self,$url,$user,$pass,$try);
                    sleep 3;
                    goto &http_get;
                }
                else {
                    return (undef,$res->status_line);
                }
        }
        else {
            return (1,$cache->save($url,$res->content));
        }
    }
    elsif($res->code eq 404 || $res->code eq 301 || $res->code eq 500) {
        $try--;
        if($try>0) {
            print STDERR "\n",$res->status_line," ($try)Try again...";
            @_ = ($self,$url,$user,$pass,$try);
            sleep 3;
            goto &http_get;
        }
        return (undef,$res->status_line); 
        
    }
    else {
#                if($try>0) {
#                    $try--;
                    print STDERR "\n",$res->status_line," ($try)Try again...";
                    @_ = ($self,$url,$user,$pass,$try);
                    sleep 3;
                    goto &http_get;
#                }
#                else {
#            return (undef,$res->status_line); 
#            }
    }
}

sub _parse_res_content {
    my $need_auth;
    my ($state,$login,%fields);
    $state=0;
    foreach my $content (@_) {
        if($content =~ /input\s+[^<>]*\s*name=['"]username['"]/i) {
            $state = 1;
        }
        elsif($content =~ /location\.reload\(\)/i) {
            $state = 2;
        }
        if((!$login) && $content =~ /\<form\s+[^<>]*\s*action=['"]([^'"]+)['"]/i) {
            $login = $1;
        }
        my @match = $content =~ /\<((?:input|select)\s+[^<>]+)/g;
        foreach(@match) {
            my ($name,$value)= /^select/ ? ("",0) :  ("","");
            if(/\s*name=['"]([^'"]*)['"]/) {
                $name = $1;
                if(/\s*value=['"]([^'"]+)['"]/) {
                    $value=$1;
                };
                $fields{$name}=$value;
            }
        }
        $fields{loginfield}="username";
        $fields{loginsubmit}="true";
    }
    return ($state,$login,%fields);# if($state);
    return undef;
}

sub _decode_data {
    my $data_ref = shift;
    return $data_ref unless(ref $data_ref);
    my $charset;
    foreach(@{$data_ref}) {
        if(/content\s*=\s*"[^"]*charset\s*=\s*([^\s"]+)[^"]*"/) {
            $charset=$1;
            last;
        }
    }
    if($charset) {
        #print STDERR "Decode content using $charset\n";
        return [map {decode($charset,$_)} @{$data_ref}];
    }
    return $data_ref;
}

sub init_with_url {
    my ($self,$url,$charset) = @_;
    $self->{url} = $url;
    $self->{charset} = $charset if($charset);
    my ($ok,@data) = $self->http_get($url);
    if($ok) {
        if($self->{charset}) {
            $self->init(map decode($self->{charset},$_),@data);
        }
        else {
            $self->init(@{_decode_data(\@data)});
        }
        return $self;
    }
    else {
        print STDERR @data;
        return undef;
    }
}

sub init {
    my ($self,@data) = @_;
    return unless($_[0]);
    if( $_[0] eq '-') {
        @data=<STDIN>;
    }
    elsif($_[0] =~ /\n/) {
        @data=@_;
    }
    elsif (-f $_[0]) {
        open FI,"<",$_[0];
        @data=<FI>;
        close FI;
    }
    else {
        @data=@_;
    }
    my $tree = HTML::TreeBuilder->new_from_content(@data);
    my ($title) = $tree->look_down("_tag",qr/title/i);
    if($title) {
        $title = $title->as_text; $title =~ s/^\s+//; $title =~ s/\s+$//;
    }
    $self->{title}=$title ? $title : "";
    my @forum_exp = (
        ["class",qr/^mainbox forumlist$/i],
        ["id",qr/^subforum$/i],
    );
    my @forums;
    foreach my $exp (@forum_exp) { 
        @forums= $tree->look_down(@{$exp});
        foreach(@forums) {
            my @links = $_->look_down("_tag","a","href",qr/forum/);
            foreach(@links) {
                push @{$self->{forums}},[$_->attr("href"),$_->as_text];
            }
        }
    }
    my @threads = $tree->look_down("_tag","a","href",qr/(:?viewthread\.php\?|thread-\d+-1)/i);
    foreach my $thread (@threads) {
        my $text = $thread->as_text;
        next if($text =~ /^[\s\d]*$/);
        my $href = $thread->attr("href");
        push @{$self->{threads}},[$href,$text];
    }
    my $pages = $tree;
    if($pages) {
        my $min=1;#10000;
        my $max=1;
        my $pre="";
        my $suf="";
        my @page_exp = (
            qr/^(.*forumdisplay\.php\?fid=\d+.*page=)(\d+)$/,
            qr/^(.*forum-\d+-)(\d+)(.+)$/,
        );
        #http://174.37.129.201/forumdisplay.php?fid=570&page=75
        foreach my $exp (@page_exp) {
            my @pages = $pages->look_down("_tag","a","href",$exp);
            #print STDERR "pages links count using $exp:",scalar(@pages),"\n";
            if(@pages) {
                foreach(@pages) {
                    my $href = $_->attr("href");
                    if($href =~ $exp) {
                        $pre=$1 || "" unless($pre);
                        $suf=$3 || "" if($3 and !$suf);
                        if($2 > $max) {
                            $pre = $1;
                            $suf = $3 if($3);
                            $max = $2;
                        }
                    }
                }
                last;
            }
        }
        $self->{pages} = [map {$pre . $_ . $suf} ($min .. $max)] if($min<=$max and ($pre or $suf));
    }
    my @postcontent;
    foreach my $class ("postmessage defaultpost","postmessage firstpost","defaultpost","firstpost","postmessage","line") {
        @postcontent = $tree->look_down("class",$class);
        last if(@postcontent);
    }
    @postcontent = $tree->look_down("id","thread_body_0") unless(@postcontent);
    $self->{posts} = \@postcontent;
    $self->{post} = $postcontent[0] if(@postcontent);
    $self->{tree}=$tree;
    return $self;
}

sub build_url {
    my($self,$url,$base) = @_;
    $base ||= $self->{url};
    return $url unless($url);
    return URI->new_abs($url,$base)->as_string;
}

sub get_post_text {
    my $self = shift;
    my $post = shift;
    return text_from_node($post);
}
sub get_post_images {
    my($self,$post) = @_;
    my @imgs = $post->look_down("_tag","img","src",qr/.+/);
    return grep /:\/\//, map $_->attr("src"),@imgs;
}
sub get_attachments {

}

sub delete {
    my $self =shift;
    $self->{posts}=undef;
    $self->{tree}->delete() if($self->{tree});
    $self->{tree}=undef;
    return 1;
}

sub DESTROY {
    my $self=shift;
    $self->delete();
    return 1;
}
1;
