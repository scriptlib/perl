#!/usr/bin/perl -w
package NightGun::StoreLoader;
use strict;
use warnings;
use NightGun;
use NightGun::Store;
my @filetype = ("Zbook","Archive","WebSaver","WWW","Files");
my @dyn_store = map {"NightGun::Store::" . $_} @filetype;
my @sta_store = ("NightGun::Store");
my %used_store = (
	"NightGun::Store"=>1,
);
my $laststore;

sub TYPE_URI {NightGun::Store::TYPE_URI}
sub TYPE_STREAM {NightGun::Store::TYPE_STREAM}

sub new {
	return bless {};
}

sub load {
    my ($self,$path) = @_;
	NightGun::message("StoreLoader","Loading $path");
    my $store = _try($path);
	while($store && $store->{data} && $store->{type}==NightGun::Store::TYPE_UNKNOWN) {
		my $again = _try($store->{id},$store->{data});
		if($again) {
			$store->{files}=$again->{files};
			$store->{dirs}=$again->{dirs};
			$store->{type}=$again->{type};
			$store->{data}=$again->{data};
		}
		else {
			last;
		}
	}
	if($store && $store->{data} && $store->{type}==NightGun::Store::TYPE_UNKNOWN) {
		my $type = NightGun::Store->type_what($store->{id});
		$store->{type}=$type;
		if($type eq TYPE_URI) {
			my $tmp = NightGun::Store->get_tempfile(
				$store->{root},
				$store->{leaf},
				);
			open FO,">",$tmp;
			print FO $store->{data};
			close FO;
			$store->{data}=$tmp;
		}
	}
   	NightGun::message("StoreLoader","Type[",$store->{type},"] Get ",
		$store->{files} ? scalar(@{$store->{files}}) : 0," files, ",
		$store->{dirs} ? scalar(@{$store->{dirs}}) : 0 , " dirs"
	);
    return $store;
}

sub _try {
	my $store;
    foreach my $class (@dyn_store,@sta_store) {
        $store = undef;
		unless($used_store{$class}) {
			eval "use $class;";
			if($@){
				NightGun::error("StoreLoader","Error: using $class");
				NightGun::error("StoreLoader",$@);
				next;
			}
		}
        NightGun::message("StoreLoader","Trying " . $class,"...");
        $store = $class->new();
        if($store->load(@_)) {
            NightGun::message("StoreLoader:","$class [OK]");
            last;
        }
        NightGun::warn("StoreLoader","$class [Failed]");
        $store = undef;
    }
	return $store;
}
1;
