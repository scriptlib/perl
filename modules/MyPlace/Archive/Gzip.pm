#!/usr/bin/perl -w
package MyPlace::Archive::Gzip;
use strict;
use warnings;
sub new {
	my ($class) = @_;
	my $self = bless {
			require_bin=>"gzip",
            name=>"gzip",
            cmd_extract=>["gzip","-dc","--","_ARCHIVE"],
            cmd_test=>["gzip","-t","-q","--"],
            file_ext=>[qr/\.(:?gz|gz2)$/],
			signature=>[0,0x1f,0x8b],
            }, $class ;
	return $self;
}
sub list_content {
    my($self,$filename)=@_;
    $filename =~ s/^.*\///g;
    $filename =~ s/\.[^\.]+$//;
    return $filename;
}
1;

