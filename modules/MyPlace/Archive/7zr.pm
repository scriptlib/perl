#!/usr/bin/perl -w
package MyPlace::Archive::7zr;
use strict;
use warnings;
sub new {
	my ($class) = @_;
	my $self = bless {
			require_bin=>"7zr",
            name=>"7zr",
            cmd_extract=>["7zr","e","-so","_ARCHIVE","_ENTRY"],
            cmd_test=>["7zr","l"],
            file_ext=>[qr/\.7z$/],
			signature=>[0,0x37,0x7a,0xbc,0xaf,0x27,0x1c],
            }, $class ;
	return $self;
}
sub list_content {
    my($self,$filename)=@_;
    open FI,"-|","7zr","l",$filename;
    my @result;
    while(<FI>) {
        #print STDERR $_;
        chomp;
        if(/^[\d-]+\s+[\d:]+\s+[\.\w\s]+\s+\d+\s+[\d\s]+\s+(.+)$/) {
            push @result,$1 . "\n";
        }
    }
	close FI;
    return @result;
}
1;

