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
	my $NDEBUG = 0;
#	print STDERR "\n***Package NightGun BEGIN***\n";
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
