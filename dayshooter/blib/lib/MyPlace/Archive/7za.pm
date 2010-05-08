#!/usr/bin/perl -w
package MyPlace::Archive::7za;
use strict;
use warnings;
sub new {
	my ($class) = @_;
	my $self = bless {
			require_bin=>"7za",
            name=>"7za",
            cmd_extract=>["7za","e","-so","_ARCHIVE","_ENTRY"],
            cmd_test=>["7za","l"],
            file_ext=>undef,
            }, $class ;
	return $self;
}
sub list_content {
    my($self,$filename)=@_;
    open FI,"-|","7za","l",$filename;
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

