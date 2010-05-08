#!/usr/bin/perl -w
package MyPlace::Archive::Bzip2;
use strict;
use warnings;
sub new {
	my ($class) = @_;
	my $self = bless {
			require_bin=>"bzip2",
            name=>"bzip2",
            cmd_extract=>["bzip2","-dc","--","_ARCHIVE"],
            cmd_test=>["bzip2","-t","-q","--"],
            file_ext=>[qr/\.(:?bz|bz2)$/],
			signature=>[0,66,90,104],
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

