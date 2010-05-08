#!/usr/bin/perl -w
package MyPlace::Archive::Tar;
use strict;
use warnings;
sub new {
	my ($class) = @_;
	my $self = bless {
			require_bin=>"tar",
            name=>"tar",
            cmd_extract=>["tar","-af","_ARCHIVE","-x","_ENTRY","-O"],
            cmd_test=>["tar","--test-label","-f"],
            cmd_list=>["tar","-taf"],
            file_ext=>[qr/\.tar$/,qr/\.tar\.(:?gz|Z|bz2)$/],
            }, $class ;
	return $self;
}
1;

