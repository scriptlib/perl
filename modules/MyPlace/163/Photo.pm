#!/usr/bin/perl -w
package MyPlace::163::Photo;
use strict;
use warnings;
use MyPlace::LWP;
my $HTTP;

use constant (
	PHOTO163=>'http://photo.163.com',
);

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
			$self->{host} = PHOTO163 . "/$initial->{$key}" unless($self->{host});
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
	my $data = get_url($url,'charset:gbk');
	if($data) {
		foreach(split('\n',$data)) {
			if(m/^\s*([\w\d_]+)\s*:\s*'([^']+)'/) {
				$self->{info}->{$1} = $2;
			}
		}
	}
	return $self->{info};
}

sub name {
	my $self = shift;
	return $self->{info}->{hostName} || $self->{hostName} || $self->{info}->{hostId};
}


sub title {
	my $self = shift;
	return $self->{info}->{hostNickName} || $self->{info}->{hostName} || $self->{title} || $self->name;
}

sub id {
	my $self = shift;
	return $self->{info}->{hostId};
}

sub info {
	my $self = shift;
	return (%{$self->{info}});
}

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
sub _convert_from_html {
    my $html_data = shift;
    if($html_data =~ m/var\s+g_[pa]\$\d+d\s*=\s*(\[\{.+\}\])\s*;/os) {
        $html_data = $1;
        $html_data =~ s/:/=>/og;
        $html_data =~ s/true/"true"/og;
        $html_data =~ s/([\%\@\$])/\\$1/og;
        my $r = eval($html_data);
        if($@) {
            print STDERR $@,"\n";
            return undef;
        }
        elsif((!$r) or (!@{$r})) {
            return undef;
        }
        return $r;
    }
    else {
        return undef;
    }
}
my $pic_host = 'http://img.ph.126.net/';
my $pic_host_1 = 'http://img';
my $pic_host_2 = '.ph.126.net/';
my $blog_host = 'http://img.bimg.126.net/photo/';
my $blog_host_1 = 'http://img';
my $blog_host_2 = '.bimg.126.net/photo/';
sub _convert_pic_url {
    my $url = shift;
    if($url =~ m/^(\d*)\/photo\/(.+)$/o) {
            return $1 ? $blog_host_1 . $1 . $blog_host_2 . $2 : $blog_host . $2;
    }
    elsif($url =~ m/^(\d*)\/(.+)$/o) {
            return $1 ? $pic_host_1 . $1 . $pic_host_2 . $2 : $pic_host . $2;
    }
}

sub get_albums_url {
    my $self = shift;
	return($self->{info}->{albumUrl}) if($self->{info}->{albumUrl});
	my $name = shift(@_) || $self->{hostName};
    if(!$name) {
        warn "No hostName specified.\n";
        return undef;
    }
#	URL=http://photo.163.com/photo/1219205481@qq.com/dwr/call/plaincall/UserSpaceBean.getUserSpace.dwr
#	callCount=1
#	scriptSessionId=${scriptSessionId}187
#	c0-scriptName=UserSpaceBean
#	c0-methodName=getUserSpace
#	c0-id=0
#	c0-param0=string:1219205481%40qq.com
#	batchId=125181
    my $api_url = 'http://photo.163.com/photo/' . $name . '/dwr/call/plaincall/UserSpaceBean.getUserSpace.dwr?';
    my $sess_id = 100+int(rand(1)*100+1);
    my $batch_id = 577000 + int(rand(1)*1000+1);
    my $request = $api_url . "callCount=1&scriptSessionId=\${scriptSessionId}$sess_id&c0-scriptName=UserSpaceBean&c0-methodName=getUserSpace&c0-id=0&c0-param0=string:$name&batchId=$batch_id";
    my $result = get_url($request);
#	print STDERR $result,"\n";
    my $albums_url;
    if($result =~ m/cacheFileUrl:"([^"]+)"/o) {
        $albums_url = 'http://' . $1;
		$self->{info}->{albumUrl} = $albums_url;
        return $albums_url;
    }
    else {
        warn $result,"\n";
        return undef;
    }
}

sub get_albums_from_js {    
    my $self = shift;
    my $albums_url = shift;
    my @QUERYS = @_;
	my $albums_data = get_url($albums_url,'charset:gbk');
    my $albums = _convert_from_html($albums_data);
    return undef unless($albums);
    if(@QUERYS) {
        my $UTF8 = find_encoding('utf-8');
        @QUERYS = map {$UTF8->decode($_)} @QUERYS;
        my @new_albums;
        foreach my $id_or_name (@QUERYS) {
            foreach(@{$albums}) {
				$_->{purl} = 'http://' . $_->{purl} unless((!$_->{purl}) and $_->{purl} =~ m/^http:/i);
				$_->{name} = $_->{desc} unless($_->{name});
                if($id_or_name eq $_->{name}) {
                    push @new_albums,$_;
                }
                elsif($id_or_name eq $_->{id}) {
                    push @new_albums,$_;
                }
            }
        }
        $albums = \@new_albums;
    }
    return $albums;
}
sub get_albums {
    my $self = shift;
    my $url = $self->get_albums_url();
	if(!$url) {
		print STDERR "No albums url found\n";
		return undef;
	}
    return $self->get_albums_from_js($url,@_);
}
sub get_pictures_from_js {
    my $self = shift;
    my $url = shift;
	my $pictures_data = get_url($url,'charset:gbk');
    my $pictures = _convert_from_html($pictures_data);
    return undef unless($pictures);
    foreach(@{$pictures}) {
        $_->{url} = _convert_pic_url($_->{ourl});
    }
    return $pictures;
}

sub get_pictures {
    my ($self,$album) = @_;
    return undef unless($album);
    my $url;
    if(!ref $album) {
        $url = $album;
    }
    else {
        $url = $album->{purl};
    }
	if(!$url) {
		print STDERR "No pictures found for " . $album->{name} . "\n";
		return undef;
	}
#    $url = 'http://' . $url unless($url =~ m/^http:/i);
    return $self->get_pictures_from_js($url);
}
1;

__END__
=pod

=head1  NAME

MyPlace::163::Photo - PERL Module

=head1  SYNOPSIS

use MyPlace::163::Photo;

=head1  DESCRIPTION

___DESC___

=head1  CHANGELOG

    2012-01-25 17:51  xiaoranzzz  <xiaoranzzz@myplace.hell>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@myplace.hell>


# vim:filetype=perl

