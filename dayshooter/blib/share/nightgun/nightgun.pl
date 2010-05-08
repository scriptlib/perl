#!/usr/bin/perl 
###APPNAME:     nightgun
###APPAUTHOR:   xiaoranzzz
###APPVER:		1.0
###APPDATE:		2009-06-20 20:17:43
###Version:		1.0 2009-06-20 20:17:43 by xiaoranzzz
###Version:		0.2 2008-12-31 05:33:17 by xiaoranzzz
###APPDESC:     text reader suitable for night reading
###APPUSAGE:	[Filename]
###APPOPTION:	
use strict;
use warnings;
our $VERSION = '1.0';
my $appdir;
my %state;


BEGIN {
	use File::Spec;
	my $binary = File::Spec->rel2abs($0);
	my ($vol, $dirs, undef) = File::Spec->splitpath($binary);
	$appdir = File::Spec->catdir($vol,$dirs);
	my $libdir = File::Spec->catdir($vol,$dirs,File::Spec->updir,File::Spec->updir,"lib");
#	print STDERR $libdir,"\n";
	unshift @INC, $libdir if -d $libdir;
		require NightGun;import NightGun;#  qw/NDEBUG/;
		require NightGun::App;import NightGun::App; 
		require NightGun::StoreLoader;import NightGun::StoreLoader; 
		require NightGun::Gui;import NightGun::Gui; 
		require NightGun::History;import NightGun::History; 
		require NightGun::Encode;
		import NightGun::Encode qw/_to_gtk _to_gtk_a _from_gtk _from_gtk_a/;
#	print STDERR join("\n",@INC);
}
my $config_dir = $ENV{HOME} . "/.nightgun";
mkdir $config_dir unless(-d $config_dir);
my $cmdline_file = shift;

NightGun::init($appdir,$config_dir);
$NightGun::Config->{History}={} unless($NightGun::Config->{History});
$NightGun::Config->{GUI}={} unless($NightGun::Config->{GUI});
$NightGun::Config->{APP}={} unless($NightGun::Config->{APP});

my $Worker = NightGun::StoreLoader->new();
my $History = NightGun::History->new($NightGun::Config);
my $GUI = NightGun::Gui->new(File::Spec->catfile($appdir, "main.glade"));
foreach(keys %{$GUI->{events}}) {
    $GUI->{events}{$_}=\&print_arg;
}
$GUI->{events}{main_select_file}=\&select_store;
$GUI->{events}{main_select_dir}=\&select_store;
$GUI->{events}{main_destory}=\&quit;
$GUI->{events}{file_list_selected}=\&select_store;
$GUI->{events}{hot_list_changed}=\&select_store;
$GUI->{events}{location_changed}=\&location_changed;
$GUI->{events}{encoding_changed}=\&reload_store;

$nightgun_global->{GUI}=$GUI;
$NightGun::nightgun_global->{History}=$History;
$NightGun::nightgun_global->{ProgramDirectory}=$appdir;
$NightGun::nightgun_global->{ConfigDirectory}=$config_dir;
$NightGun::nightgun_global->{State}=\%state;
$NightGun::nightgun_global->{StoreLoader}=*load_store;

&load_config;
$GUI->run;

$NightGun::nightgun_global = undef;
NightGun::Store::destory();
NightGun::destory();
exit 0;

use URI::Escape;
sub location_changed {
	return if($state{store_loading});
    return unless($state{store});
	my $location = shift;
	return if($location eq 'about:blank');
	$location = uri_unescape(_from_gtk($location));
    NightGun::message("","Location Changed $location");
    my ($root,$leaf) = $state{store}->parse_location($location); 
    NightGun::message("","Root:",$root);
    NightGun::message("","Leaf:",$leaf);
#    if(not($root eq $state{store}->{root})) {
#        load_store($root);
#    }
    if($leaf) {
    #    print STDERR "Location:$leaf\n";
        $state{store}->{leaf}=$leaf;
        $state{id}=$leaf;
        &update_ui;
    }
}
sub print_arg {
    print STDERR @_,"\n";
}

sub select_store {
    my $file=shift;
    load_store(_from_gtk($file),1) if($file);
}

sub reload_store {
    return load_store($state{id});
}

sub load_store {

	$state{store_loading}=1;
    my $path = shift;
    my $flag = shift;
    $GUI->content_begin_set;
    $GUI->statusbar_set("Loading " . $path);
    NightGun::message(
		"load_store",$path
	);
	my $store;
	my $to_parent;
	if($path =~ /^PARENT:/) {
		$path =~ s/^PARENT://;
		$to_parent=1;
	}
	if($state{store}) {
        my @info = $GUI->content_get_position;
        $History->add($state{store}->{id},@info) if(@info and $info[0] and $GUI->content_get());
	}
	$store = $Worker->load($path) unless($store);
	unless($store) {
		NightGun::message("load_store","Unable to load $path");
		$state{store_loading}=0;
		return undef;
	}

    $GUI->content_progress_set;
	if($store->{type} == $Worker->TYPE_URI) {
	    $GUI->content_set_uri(_to_gtk($store->{data}));
	}
	else {
	    $GUI->content_set_stream($store->{data});
	}
	
    $GUI->content_progress_set;
    $GUI->main_set_title(_to_gtk($store->{title} ? "NightGun - " . $store->{title} : "NightGun"));
    if(!($store->is_single)) {
    	$GUI->content_progress_set;
    	my @lists;
	    push @lists,"../","PARENT:" . $store->{parent} if($store->{parent});
    	if($store->{dirs}) {
        	push @lists,
				map {my $t=$_;$t =~ s/\/$//g;$t =~ s/^.*\///;($t . "/",$_)}
					@{$store->{dirs}};
	    }
    	if($store->{files}) {
        	push @lists,
				map {my $t=$_;$t =~ s/^.*(:?\/|::)//;($t,$_)} @{$store->{files}};
	    }	
    	$GUI->content_progress_set;
	    $GUI->file_list_set(_to_gtk_a(@lists));
    }
    $state{store}=$store;
    $state{id}=$store->{id};
    &update_ui;
    $GUI->content_progress_set;
    $GUI->content_end_set;
    $GUI->statusbar_set("Loaded");
    if($store->{leaf}) {
		$History->add($store->{root},$store->{leaf}) if($store->{leaf} =~ /[^\/\\]$/);
	}
	elsif($to_parent) {
	}
	elsif((!$store->is_single) and ($store->{root} !~ /\/$/) and (!$store->{data})) {
        my @history_info = $History->get($store->{root});
		if($history_info[0] && $history_info[0] =~ /[^\/\\]$/) {
        	NightGun::message("load_store",
				"NO leaf,Try loading from history entry");
			load_store($history_info[0],$flag);
		}
	}
	$state{store_loading}=0;
}

sub update_ui {
    $GUI->hot_list_set_text(_to_gtk($state{id}));
    $GUI->statusbar_set(_to_gtk($state{id}));
    $GUI->file_list_select_item(_to_gtk($state{id}));
    my @history_info = $History->get($state{id});
	return unless(@history_info);
	return unless($history_info[1]);
	$GUI->update();
	$GUI->content_set_position(@history_info);
}

sub save_config {
    $GUI->save_config($NightGun::Config->{GUI});
    $NightGun::Config->{APP}->{last_location} = $state{store}->{root} if($state{store});
    $NightGun::Config->{APP}->{hot_list} = [_from_gtk_a($GUI->hot_list_get_texts)];
    if($state{store}) {
        my @info = $GUI->content_get_position;
        $History->add($state{store}->{id},@info) if(@info and $info[0] and $info[1]);
    }
}

sub load_config {
    $GUI->load_config($NightGun::Config->{GUI});
    my $laststore=$NightGun::Config->{APP}->{last_location};
#    print STDERR "LastStore:$laststore\n";exit 0;
    if($NightGun::Config->{APP}->{hot_list}) {
        foreach(@{$NightGun::Config->{APP}->{hot_list}}) {
            $GUI->hot_list_add_uniq(_to_gtk($_));
        }
    }
    if($cmdline_file) {
		if(-e $cmdline_file) {
			unless($cmdline_file =~ /^\//) {
				my $pwd = `pwd`;
				chomp($pwd);
				$cmdline_file = "$pwd/$cmdline_file";
			}
		}
        load_store($cmdline_file);
    }
    else {
        load_store($laststore) if($laststore);
    }
}

sub quit {
    &save_config;
}


