#!/usr/bin/perl -w
package MyPlace::Archive::Zip;
use strict;
use warnings;

sub new {
	my ($class) = @_;
	my $self = bless {
			require_bin=>"unzip",
            name=>"unzip",
            cmd_extract=>["unzip","-p"],
            cmd_list=>["unzip","-Z1"],
            cmd_test=>["unzip","-Zh"],
            file_ext=>[qr/\.zip$/],
			signature=>[0,0x50,0x4B,0x03,0x04],
            }, $class ;
	return $self;
}

1;

