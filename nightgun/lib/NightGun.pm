package NightGun;
use Data::Dumper;
use constant CONFIG_FILE=>"Config.pm";
our $AppDir;
our $ConfigDir;
our $Config;
our %Global;
our $nightgun_global = \%Global;
BEGIN {
	require Exporter;
	our @ISA=qw/Exporter/;
	our @EXPORT = qw/$nightgun_global/;
#	print STDERR "\n***Package NightGun BEGIN***\n";
        $NDEBUG = 1 unless($ENV{NIGHTGUN_DEBUG});
	sub import {
		my @what;
		#die(scalar(@_) . ":@_\n");
		foreach(@_) {
			if($_ eq "NDEBUG") {
				$NDEBUG=1;
			}
			else {
				push @what,$_;
			}
			NightGun->export_to_level(1,@what);
		}
		if($NDEBUG) {
			sub message{1};
			sub warn{1};
			sub error{1};
			sub say{1};
			sub dump{1};
		}
		else {
			require NightGun::Debug;
			import NightGun::Debug;
		}
	}
}

sub init {
    ($AppDir,$ConfigDir)=@_;
    &loadConfig;
}

sub destory {
    &saveConfig;
}

sub readSetting {
    return $Config->{shift};
}
sub writeSetting {
    $Config->{shift}=@_;
}
sub loadConfig {
    open FI,"<",$ConfigDir . "/" . CONFIG_FILE;
    my $text = join("",<FI>);
    close FI;
    eval $text;
}

sub saveConfig {
    #use Data::Dumper;print Data::Dumper->Dump([$NightGun::Config],["Config"]),"\n";
    local $Data::Dumper::Purity = 1;
    open FO,">",$ConfigDir . "/" . CONFIG_FILE;
    print FO Data::Dumper->Dump([$Config],["Config"]);
    close FO;
}
1;

package NightGun::History;
use NightGun;
use strict;

sub new {
    my ($class,$config)=@_;
    my $self = bless {
        },$class;
    $config->{History}={} unless($config->{History});
    $self->{data}=$config->{History};
    #use Data::Dumper;print Dumper($self->{data}),"\n";
    return $self;
}

sub add {
    my ($self,$file,@info)=@_;
	if($file) {
	    $self->{data}->{$file}=\@info;
		NightGun::App::message("History","add ",$file,":",join(" ",@info));
	}
}

sub get {
    my ($self,$file)=@_;
    return undef unless($self->{data}->{$file});
    NightGun::App::message("History","get ",$file,":",join(" ",@{$self->{data}{$file}}));
    return @{$self->{data}->{$file}};
}
sub save {
    return;
}
1;
package NightGun::Recents;
use NightGun;
use strict;
use constant RECENTS_ITEM_MAX=>100;
sub new {
    my ($class,$config,$max_log)=@_;
    my $self = bless {
        },$class;
    $config->{Recents}=[] unless($config->{Recents});
    $self->{data}=$config->{Recents};
    return $self;
}

sub add {
    my ($self,$id)=@_;
    push @{$self->{data}},$id;
    NightGun::App::message("Recents","add $id");
}

sub save {
    return;
}
1;
