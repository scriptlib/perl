#!/usr/bin/perl -w
package MyPlace::Search::Sogou;
use strict;
use warnings;

BEGIN {
#    sub debug_print {
#        return unless($ENV{XR_PERL_MODULE_DEBUG});
#        print STDERR __PACKAGE__," : ",@_;
#    }
#    &debug_print("BEGIN\n");
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw(sogou_search_image);
    @EXPORT_OK      = qw(search_images);
}

#http://image.soso.com/image.cgi?_=1326653407401&w=%B3%BF%C4%DD&icext=1&ic=one&pg=0&ity=0&scr=&ext=0&mc=0&simi=0&fid=&sf=0&wpic=0&tid=
my %FUNCTION = (
    'images'=> {
        'base'=>'http://pic.sogou.com/d?w=05009900&',
        'params'=> {
            'mode'=>1, #1=all,2=large,5=wallpaper,8=picset,9=qqhead
            'dheight'=>undef, #screen size
            'dwidth'=>undef, #screen size
            'dm'=>undef,#size for all:0=all,1=large,2=medium,3=small,4=custom
            'cheight'=>undef,'cwidth'=>undef,#custom size for all
            'dq'=>undef,#size for qqhead:0=all,1=40x40,2=100x100,3=128x128,4=custom
            'qheight'=>undef,'qwidth'=>undef,#custome size for qqhead
            'di'=>undef,#size for wallpaper,0=screen,1=800x600,2=1024x768,3=1280x960,4=1600*1200,5=1280*800,6=1400*900,7=1600*1000,8=1920*1200
            'mood'=>undef, #color:0=all,1=bw,3=blue,4=green,5=red,6=紫,7=yellow
            'dr'=>undef,
            'did'=>undef,
            'page'=>1,
            'query'=>undef,
        },

    },
);

my %MAP_TYPE = (
    'all'=>1,
    'large'=>2,
    'wallpaper'=>5,
    'picset'=>8,
    'qqhead'=>9,
);
my %MAP_SIZE = (
    'all'=>0,
    'large'=>1,
    'medium'=>2,
    'small'=>3,
    'custom'=>4,
);

use Encode;
use utf8;
my $_utf8 = find_encoding('utf8');
my $_gb = find_encoding('gbk');
use URI::Escape;
use MyPlace::Search;

my $GET_IMAGE = 'http://pic.sogou.com/su?k=$1&tc=1&t=0,2&id=1&d=';
sub get_images {
    my (undef,$data) = get_url($GET_IMAGE . join(',',@_),undef,$_gb);
    my @r;
	$data =~ s/([\@\$\%])/\\$1/g; 
    while($data =~ m/window\.\w+\s*=\s*(\[[^\]]+\];)/g) {
        push @r,eval($1);
    }
   return @r; 
}

sub search_images {
	my $keyword = shift;
	my $page = shift;
	if($page and $page !~ m/^\d+/) {
		unshift @_,$page;	
		$page = undef;
	}
	my %options = @_;
	$options{page} = $page if($page);
    my %url_options;
    if($options{type} and defined $MAP_TYPE{$options{'type'}}) {
        $url_options{mode}=$MAP_TYPE{$options{'type'}};
        delete $options{'type'};
    }
    if($options{size} and defined $MAP_SIZE{$options{'size'}}) {
        $url_options{dm}=$MAP_SIZE{$options{'size'}};
        delete $options{'size'};
    }
    foreach my $key (keys %{$FUNCTION{images}->{params}}) {
        my $def = $FUNCTION{images}->{params}->{$key};
        my $new = $options{$key};
        if(defined $new) { 
            $url_options{$key} = $new;
        }
        elsif(defined $url_options{$key}) {
        }
        elsif(defined $def) {
            $url_options{$key} = $def;
        }
    }
    $url_options{did} = ($url_options{page} - 1)*20 + 1;
    $url_options{query} = $keyword unless($url_options{'query'});
    $url_options{query} = build_keyword($url_options{'query'},1);
    $url_options{query} = uri_escape($_gb->encode($_utf8->decode($url_options{query})),'^\-_~\"\+a-zA-z0-9');
    my $url = build_url($FUNCTION{images}->{base},\%url_options);
    my (undef,$data) = get_url($url,$url,$_gb);
    my @images;
	$data =~ s/([\@\$\%])/\\$1/g; 
    while($data =~ m/var jsimg\w+\s*=\s*(\[[^\]]+\];)/g) {
        push @images,eval($1);
    }
    #push @ds,split(/\s+/,$1);
    my @imgs_code;
    foreach(@images) {
        if($_->[7] and (!($_->[7] eq 'null'))) {
            push @imgs_code,split(/\s+/,$_->[7]);
        }
    }
    my $count = 0;
    my @codes_splice;
    foreach(@imgs_code) {
        if($_) {
            $count ++;
            push @codes_splice,$_;
            if($count >= 10) {
                push @images,get_images(@codes_splice);
                @codes_splice = ();
                $count = 0;
            }
        }
    }
    if(@codes_splice) {
        push @images,get_images(@codes_splice);
    }
    my @result;
    foreach(@images) {
        push @result, {
            'url'=>$_->[0],
            'refer'=>$_->[1],
            'name'=>$_->[2],
            'width'=>$_->[3],
            'height'=>$_->[4],
            'size'=>$_->[5],
        };
    }
    #join("\n",map $_->[0],@result),"\n";
    return scalar(@result),\@result;
}

sub sogou_search_images {
    goto search_image;
}

1;
