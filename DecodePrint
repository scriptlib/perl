#!/usr/bin/perl -w

use Encode qw/find_encoding/;
my $utf8 = find_encoding('utf8');
my @data;
foreach(@ARGV) {
	push @data,[$_,$utf8->encode($_),$utf8->decode($_)];
}
use Data::Dumper;
print STDERR Data::Dumper->Dump([\@data],['data']),"\n";
