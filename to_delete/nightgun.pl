#!/usr/bin/perl 
###APPNAME:     nightgun
###APPAUTHOR:   xiaoranzzz
###APPDATE:	2008-12-31 05:33:17
###APPVER:	0.2
###APPDESC:     text reader suitable for night reading
###APPUSAGE:	[Filename]
###APPOPTION:	
use strict;
no warnings;
#ENV variable MUST be defined somewhere,
#FOR perl to search modules from,
#OR nothing will work
unshift @INC,$ENV{XR_PERL_MODULE_DIR};
use lib $ENV{XR_PERL_MODULE_DIR};
use MyPlace::Script::Usage qw/help_required/;
exit 0 if(help_required($0,@ARGV));

use NightGun qw/$nightgun_global/;
use NightGun::App;
use NightGun::StoreLoader;
use NightGun::Gui;
use NightGun::History;
use MyPlace::Encode;

my $appdir = $ENV{XR_PERL_MODULE_DIR} . "/NightGun";
my $config_dir = $ENV{HOME} . "/.nightgun";
mkdir $config_dir unless(-d $config_dir);
my %state;
my $cmdline_file = shift;

NightGun::init($appdir,$config_dir);
$NightGun::Config->{History}={} unless($NightGun::Config->{History});
$NightGun::Config->{GUI}={} unless($NightGun::Config->{GUI});
$NightGun::Config->{APP}={} unless($NightGun::Config->{APP});

my $Worker = NightGun::StoreLoader->new();
my $History = NightGun::History->new($NightGun::Config);
my $GUI = NightGun::Gui->new($appdir . "/main.glade");
foreach(keys %{$GUI->{events}}) {
    $GUI->{events}{$_}=\&print_arg;
}
$GUI->{events}{main_select_file}=\&load_store;
$GUI->{events}{main_select_dir}=\&load_store;
$GUI->{events}{main_destory}=\&quit;
$GUI->{events}{file_list_selected}=\&load_store;
$GUI->{events}{hot_list_changed}=\&load_store;
$GUI->{events}{location_changed}=\&location_changed;
$GUI->{events}{encoding_changed}=\&reload_store;

$nightgun_global->{GUI}=$GUI;
$nightgun_global->{History}=$History;
$nightgun_global->{ProgramDirectory}=$appdir;
$nightgun_global->{ConfigDirectory}=$config_dir;
$nightgun_global->{State}=\%state;
$nightgun_global->{StoreLoader}=*load_store;

&load_config;
$GUI->run;

$nightgun_global = undef;
NightGun::destory;
exit 0;

sub location_changed {
	return if($state{store_loading});
    return unless($state{store});
    my ($root,$leaf) = $state{store}->parse_location(@_); 
    NightGun::message("","Location Changed");
    NightGun::message("","Root:",$root);
    NightGun::message("","Leaf:",$leaf);
    if(not($root eq $state{store}->{location}->[0])) {
        load_store($root);
    }
    if($leaf) {
    #    print STDERR "Location:$leaf\n";
        $state{store}->{location}->[1]=$leaf;
        $state{path}=$leaf;
        &update_ui;
    }
}
sub print_arg {
    print STDERR @_,"\n";
}


sub select_store {
    my $file=shift;
    load_store($file,1) if($file);
}

sub reload_store {
    return load_store($state{path});
}

sub load_store {
	$state{store_loading}=1;
    my $path = shift;
    my $flag = shift;
    $GUI->content_begin_set;
    $GUI->statusbar_set("Loading " . $path);
    #print STDERR "Loading Store : $path\n";
    my $store = $Worker->load($path);

    #use Data::Dumper;print STDERR Dumper($store),"\n";
    #print STDERR "Store :\t" . join("\t",@{$store->{location}}),"\n";
    #print STDERR "Store type:\t" . $store->{filetype},"\n";
    $GUI->content_progress_set;
    if($store->{single}) {
        NightGun::message("","Single store,no list");
    }
    else {
        my @lists;
        push @lists,"../",$store->{parent};
        if($store->{directories}) {
            push @lists,map {my $t=$_;$t =~ s/\/$//g;$t =~ s/^.*\///;($t . "/",$_)} @{$store->{directories}};
        }
        if($store->{files}) {
            push @lists,map {my $t=$_;$t =~ s/^.*\///;($t,$_)} @{$store->{files}};
        }
        $GUI->file_list_set(@lists);
    }
    $GUI->content_progress_set;
    if($store->{save_history}) {
        my @history_info = $History->get($store->{location}->[0]);
        if(!$store->{single} and !$store->{location}->[1] and $history_info[0]) {
        NightGun::message("","Load from history entry");
                $path = shift @history_info;
                $store->load($path);
        }
    }
    $GUI->content_progress_set;
    if($state{store}) {
        my @info = $GUI->content_get_position;
        $History->add($state{store}->{path},@info) if(@info and $GUI->content_get());
        if($state{store}->{save_history}) {
            $History->add(@{$state{store}->{location}});
        }
    }
    $GUI->content_progress_set;
    $GUI->content_set($store);
    $GUI->content_progress_set;
    $state{store}=$store;
    $state{path}=$store->{path};
    $GUI->main_set_title($store->{title} ? "NightGun - " . $store->{title} : "NightGun");
    &update_ui;
    $GUI->content_progress_set;
    $GUI->content_end_set;
    $GUI->statusbar_set("Loaded");
	$state{store_loading}=0;
}

sub update_ui {
    $GUI->hot_list_set_text($state{path});
    $GUI->statusbar_set($state{path});
    $GUI->file_list_select_item($state{path});
    my @history_info = $History->get($state{path});
    $GUI->content_set_position(@history_info) if(@history_info);
}

sub save_config {
    $GUI->save_config($NightGun::Config->{GUI});
    $NightGun::Config->{APP}->{last_location} = $state{store}->{location}->[0] if($state{store});
    $NightGun::Config->{APP}->{hot_list} = [$GUI->hot_list_get_texts];
    if($state{store}) {
        my @info = $GUI->content_get_position;
        $History->add($state{store}->{path},@info) if(@info);
        if($state{store}->{save_history}) {
            $History->add(@{$state{store}->{location}});
        }
    }
}

sub load_config {
    $GUI->load_config($NightGun::Config->{GUI});
    my $laststore=$NightGun::Config->{APP}->{last_location};
#    print STDERR "LastStore:$laststore\n";exit 0;
    if($NightGun::Config->{APP}->{hot_list}) {
        foreach(@{$NightGun::Config->{APP}->{hot_list}}) {
            $GUI->hot_list_add($_);
        }
    }
    if($cmdline_file) {
		if(-f $cmdline_file) {
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


