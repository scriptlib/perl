#!/usr/bin/perl -w
package MyPlace::Archive::Rar;
use strict;
use warnings;
sub new {
	my ($class) = @_;
	my $self = bless {
			require_bin=>"unrar",
            name=>"rar",
            cmd_extract=>["unrar","p","-inul","--"],
            cmd_list=>["unrar","vb","--"],
            cmd_test=>["unrar","t","-inul","--"],
            file_ext=>[qr/\.rar$/],
			signature=>[0,0x52,0x61,0x72,0x21,0x1A,0x07,0x00],
            }, $class ;
	return $self;
}

1;

