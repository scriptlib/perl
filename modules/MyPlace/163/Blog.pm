#!/usr/bin/perl -w
package MyPlace::163::Blog;
use strict;
use warnings;
use Encode;
use MyPlace::LWP;
my $HTTP;

use constant (
	BLOG163=>'http://blog.163.com',
);

sub get_url {
	$HTTP = MyPlace::LWP->new('progress'=>1) unless($HTTP);
	my $url = shift;
	print STDERR "Retriving $url  ";
	my ($status,$data,$res) = $HTTP->get($url,@_);
	if($status) {
		print STDERR "\t",$res->status_line,"\n";
		return $data;
	}
	else {
		print STDERR "\t",$res->status_line,"\n";
		return undef;
	}
}

sub new {
	my $class = shift;
	my $self = bless {},$class;
	$self->{initial} = @_ ? {@_} : {};
	$self->_init;
	return $self;
}

sub _init {
	my $self = shift;
	my $initial = $self->{initial};
	unless($self->{host}) {
		foreach my $key(qw/host url hostAlbumUrl/) {
			if($initial->{$key}) {
				$self->{host} = $initial->{$key};
				last;
			}
		}
	};
	foreach my $key(qw/hostName name userName/) {
		if($initial->{$key}) {
			$self->{host} = BLOG163 . "/$initial->{$key}" unless($self->{host});
			$self->{hostName} = $initial->{$key};
			last;
		}
	}
	return $self;
}


sub init {
	my $self = shift;
	my $url = shift(@_) || $self->{host};
	return undef unless($url);
	print STDERR "Retriving USER information ...\n";
	my $result = &get_url($url,'charset:gbk');
#userId:188090284
#,userName:'zyayoyo'
#,nickName:'张优'
#,imageUpdateTime:1318437641442
#,baseUrl:'http://zyayoyo.blog.163.com/'
#,gender:'他'
#,email:'1219205481@qq.com'
#,photo163Name:'1219205481@qq.com'
#,photo163HostName:'1219205481@qq.com'
#,TOKEN_HTMLMODULE:''
#,isMultiUserBlog:false
#,isWumiUser:true
#,sRank:-100
	if($result) {
		while($result =~ m/(userId|userName|nickName|baseUrl|gender|imageUpdateTime|email|photo163Name|photo163HostName)\s*:\s*('?)(\d+|[^']+)\2/g) {
			$self->{info}->{$1} = $3;
		}
	}
	else {
		return undef;
	}
	return $self->{info};
}

sub name {
	my $self = shift;
	return $self->{info}->{userName} || $self->{hostName} || $self->{userId};
}

sub title {
	my $self = shift;
	return $self->{info}->{nickName} || $self->name;
}

sub id {
	my $self = shift;
	return $self->{info}->{userId};
}

sub info {
	my $self = shift;
	return (%{$self->{info}});
}

sub albumId {
	my $self = shift;
	return $self->{info}->{photo163Name};
}

sub get_blogs {
    my $self = shift;
	my $id = shift(@_) || $self->id;
	my $name = shift(@_) || $self->name;
    if(!$name) {
        warn "No name specified.\n";
        return undef;
    }
	if(!$id) {
		warn "No id specified.\n";
		return undef;
	}
    my $api_url = 'http://api.blog.163.com/' . $name . '/dwr/call/plaincall/BlogBeanNew.getBlogs.dwr?';
    my $sess_id = 100+int(rand(1)*100+1);
    $api_url = $api_url . join("&", 
						"callCount=1",
						"scriptSessionId=\${scriptSessionId}$sess_id",
						"c0-scriptName=BlogBeanNew",
						"c0-methodName=getBlogs",
						"c0-id=0",
						"c0-param0=number:$id"
					);
	my $pos = 0;
	my $length = 100;
    $HTTP = MyPlace::LWP->new() unless($HTTP);
	my @blogs;
	while(1) {
		my $batch_id = 577000 + int(rand(1)*1000+1);
		my $url = join("&",$api_url,
					"c0-param1=number:$pos",
					"c0-param2=number:$length",
					"batchId=$batch_id"
				 );

#	callCount=1
#	scriptSessionId=${scriptSessionId}187
#	c0-scriptName=BlogBeanNew
#	c0-methodName=getBlogs
#	c0-id=0
#	c0-param0=number:188090284
#	c0-param1=number:0
#	c0-param2=number:20
#	batchId=532464
		print STDERR "Retriving $url...";
	    my ($status,$result) = $HTTP->get($url);
		print STDERR "\n\t[$status]\n";
		#print STDERR "$result\n";
		my @matched;
		while($result =~ m/s\d+\.permalink="([^"]+)/g) {
			#print $1,"\n";
			push @matched,"http://blog.163.com/$name/$1";
		}
		if(@matched) {
			push @blogs,@matched;
			if(@matched < $length) {
				last;
			}
		}
		else {
			last;
		}
		$pos += $length;
	}
	return @blogs ? \@blogs : undef;
}

sub extract_images {
	my $self = shift;
	my $blog = shift;
	my $data = get_url($blog,'charset:gbk');
	return undef unless($data);
	my %album = (title=>undef,images=>[]);
	foreach(split('\n',$data)) {
		while(m/src="(http:\/\/img\.ph[^"]+)/og) {
			push @{$album{images}},$1;
		}
		if((!$album{title}) and m/\<title\>(?:【引用】)?([^<]+) - [^"]+ - [^"]+\</) {
			$album{title} = $1;
		}
	}
	return \%album if(@{$album{images}});
}

1;
