package MyPlace::Discuz;
use strict;
use lib $ENV{XR_PERL_MODULE_DIR};
use HTML::TreeBuilder;
#use LWP::UserAgent;
#use HTTP::Cookies;
use MyPlace::Curl;
use URI;
use Encode qw/decode from_to encode/;
use MyPlace::HTML::Convertor;
my $CURL;
my $COOKIE_FILENAME = $ENV{'HOME'} . "/.discuz_cookie.curl";
my %login_try;
#my $cache = MyPlace::Cache->new("httpget");

sub download {
    my ($self,$url,$filename) = @_;
    $CURL = _make_curl_object() unless($CURL);
    $CURL->get($url,"--referer",$url,"--output",$filename);
}

sub new {
    my $class=shift;
    return bless{@_} ,$class;
}


sub get_url {
    my $self = shift;
    my $url = shift;
    $CURL = _make_curl_object() unless($CURL);
    return $CURL->get($url);
}

sub _make_curl_object 
{
    my $CURL = MyPlace::Curl->new;
    $CURL->set("cookie",$COOKIE_FILENAME);
    $CURL->set("cookie-jar",$COOKIE_FILENAME);
    $CURL->set("user-agent","Mozilla/5.0");# (X11; U; Linux i686; en-US; rv:1.9.0.3) Gecko/2008092416 Firefox/3.0.3 Firefox/3.0.1");
    return $CURL;
}

sub _do_login {
    my($url,$referer,$user,$pass) = @_;
    $CURL = _make_curl_object() unless($CURL);
    my $action;
    my %posts;
    my ($code,@data) = $CURL->get($url,"--referer",$referer);
    foreach my $content (@data)
    {
        if($code == 0)
        {
            if((!$action) and $content =~ /\<form\s+[^<>]*\s*action=['"]([^"]*log[^'"]+)['"]/i) {
                $action = $1;
            }
            my @match = $content =~ /\<((?:input|select)\s+[^<>]+)/g;
            foreach(@match) {
                my ($name,$value)= /^select/ ? ("",0) :  ("","");
                if(/\s*name=['"]([^'"]*)['"]/) {
                    $name = $1;
                    if(/\s*value=['"]([^'"]+)['"]/) {
                        $value=$1;
                    };
                    #next if($name =~ m/^(?:handlekey|cookietime|answer|email)$/i);
                    $posts{$name}=$value;
                }
            }
        }
        else 
        {
            print STDERR "Error: ",$CURL->error_message($code),"\n";
            return undef;
        }
    }
    if($action)
    {
        $action = URI->new_abs($action,$url);
    }
    else
    {
        print STDERR "Error: Login form not found!\n";
        return undef;
    }
    $posts{loginfield}="username";
    $posts{loginsubmit}="yes";
    $posts{username}=$user;
    $posts{password}=$pass;
    $action =~ s/&amp;/&/g if($action);
    $posts{referer}=$referer;
    my @posts = map "$_=$posts{$_}",keys %posts;
    return $CURL->post($action,$referer,%posts);
    #join("&",@posts),"--referer",$referer);
}

sub http_get {
    my($self,$url,$user,$pass,$try) = @_;
    return (undef,"Invalid url\n") unless($url);
    if($url =~ /\?/) {
        $url = "$url&adult=agreed" unless($url =~ /adult=agreed/);
    }
#    my @cached = $cache->load($url);
#    return (1,@cached) if(@cached);
    $user ||= $self->{user};
    $pass ||= $self->{pass};
    $CURL = _make_curl_object() unless($CURL);
    $try = 6 unless[$try] ;
    my ($res,@data) = $CURL->get($url,"--silent","--referer",$url);
	#die($res,@data);
    #my $req = HTTP::Request->new(GET => $url);
    #my $res = $CURL->request($req);
    if($res == 0) {
        my($state,$login,%posts) = _parse_res_content(@data);
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
            print STDERR "$login...\n";
            ($res,@data) = $CURL->post($login,$url,%posts);
            if($res == 0) {
                @_ = ($self,$url,$user,$pass);
                sleep 3;
                goto &http_get;
            }
            else {
                $try--;
                if($try>0) {
                    print STDERR "Error: ",$CURL->error_message($res),", [$try] Try again...\n";
                    @_ = ($self,$url,$user,$pass,$try);
                    sleep 3;
                    goto &http_get;
                }
                else {
                    return (undef,join('',@data));
                }
            }
        }
        elsif($state == 2) {
                $try--;
                if($try>0) {
                    print STDERR " [$try] Reloading...";
                    @_ = ($self,$url,$user,$pass,$try);
                    sleep 3;
                    goto &http_get;
                }
                else {
                    return (undef,@data);
                }
        }
        elsif($state == 3 and $login) {
            print STDERR "No login, go to login page...\n";
            $login = URI->new_abs($login,$url);
            print STDERR "$login...\n";
            _do_login($login,$url,$user,$pass);
            sleep 1; 
            print STDERR "Reloading $url...\n";
            @_ = ($self,$url,$user,$pass,$try);
            goto &http_get;
#            $self->http_get($login,$user,$pass,$try);
#            return $self->http_get($url,$user,$pass,$try);
        }
        else {
            return (1,@data);
            #$cache->save($url,@data));
            #$res->content));
        }
    }
#    elsif($res eq 404 || $res eq 301 || $res eq 500) {
    else 
    {
        $try--;
        if($try>0) {
            print STDERR "\n Error:", $CURL->error_message($res),", [$try] Retry in 1 seconds...";
            @_ = ($self,$url,$user,$pass,$try);
            sleep 1;
            goto &http_get;
        }
        return (undef,@data);
        
    }
#    else {
#                if($try>0) {
#                    $try--;
#                    print STDERR "\nHTTP Error:",$res,", Re-connecting in 3 seconds...";
#                    @_ = ($self,$url,$user,$pass,$try);
#                    sleep 3;
#                    goto &http_get;
#                }
#                else {
#            return (undef,$res->status_line); 
#            }
#    }
}

sub _parse_res_content {
    my $need_auth;
    my ($state,$login,%fields);
    $state=0;
    my $content = join("",@_);
#    foreach my $content (@_) {
        if($content =~ /\<form\s+[^<>]*\s*action=['"]([^"]*log[^'"]+)['"]/i) {
            $login = $1;
        }
        if($content =~ /input\s+[^<>]*\s*name=['"]username['"]/i) {
            $state = 1;
        }
		elsif($content =~ /ajaxget\(\'([^']*login[^']*)'/) {
			$login = $1;
			$state = 3;
		}
        elsif($content =~ /location\.reload\(\)/i) {
            $state = 2;
        }
        #elsif($content =~ /href="([^"]+\.php\?action=login[^"]*)"/) {
        #    $state = 3;
        #    $login = $1;
        #}
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
 #   }
    $login =~ s/&amp;/&/g if($login);
    return ($state,$login,%fields);# if($state);
    return undef;
}

sub to_utf8 {
	my $charset = shift;
	my $data_ref = shift;
	return map encode('utf8',decode($charset,$_)),@{$data_ref} if($data_ref);
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
		my @data = to_utf8($charset,$data_ref);
		return \@data if(@data);
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
            $self->init(to_utf8($self->{charset},\@data));
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
		["id",qr/^subforum_\d+/],
    );
    my @forums;
	my %U = ();
    foreach my $exp (@forum_exp) { 
        @forums= $tree->look_down(@{$exp});
        foreach(@forums) {
            my @links = $_->look_down("_tag","a","href",qr/(?:forumdisplay|forum-\d+-1\.html)/);
            foreach(@links) {
				my $text = $_->as_text;
				my $href = $_->attr("href");
				if($text and (!$U{$href})) {
					push @{$self->{forums}},[$_->attr("href"),$text];
					$U{$href} = 1;
				}
            }
        }
    }
    my @threads = $tree->look_down("_tag","a","href",qr/(?:mod=viewthread\&tid=|viewthread\.php\?|thread-\d+-1|read\.php\?tid-\d+\.html$)/i);
	%U = ();
    foreach my $thread (@threads) {
        my $text = $thread->as_text;
        next if($text =~ /^[\s\d]*$/);
        my $href = $thread->attr("href");
		next if($href =~ m/#/);
		next if($U{$href});
		$U{$href} = 1;
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
			qr/^(.*mod=forumdisplay&fid=\d+.*page=)(\d+)$/,
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
        $self->{pages} = [map {$pre . $_ . $suf} ($min .. $max)] if($min<$max and ($pre or $suf));
    }
    my @postcontent;
    #foreach my $class ("postmessage defaultpost","postmessage firstpost","defaultpost","firstpost","postmessage","line") {
    #foreach my $class ('^(?:postmessage defaultpost$|postmessage firstpost$|defaultpost$|firstpost$|postmessage)','^line$') {
	foreach my $class (qw/defaultpost ^pcb$ ^tpc_content$ ^line$/) {
        @postcontent = $tree->look_down("class",qr/$class/);
        last if(@postcontent);
    }
    @postcontent = $tree->look_down("id","thread_body_0") unless(@postcontent);
    $self->{posts} = \@postcontent;
    if(@postcontent) 
    {
        $self->{post} = $postcontent[0];
        my @attachment= $postcontent[0]->look_down("_tag","a", "href",qr/attachment\.php\?/);
        foreach(@attachment) {
            push @{$self->{attachment}},[$_->attr("href"),$_->as_text];
        }
    }
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

__END__

=pod
=head1 CHANGELOG
    2010-06-17  xiaoranzzz <xiaoranzzz@gmail.com>
        * Make usage of MyPlace::Curl instead of LWP
        * Add method 'download'
    2010-06-18  xiaoranzzz <xiaoranzzz@gmail.com>
        * Remove usage of MyPlace::Cache
=cut
