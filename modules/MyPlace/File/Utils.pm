#!/usr/bin/perl -w
use strict;
use warnings;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw();
    @EXPORT_OK      = qw(file_write file_read file_touch);
}

sub file_write {
	my $filename = shift;
	my $mode = shift(@_) || '>';
	open FO,$mode,$filename or return undef;
	print FO @_ if(@_);
	close FO;
	return 1;
}

sub file_read {
	my $filename = shift;
	my $mode = shift(@_) || '<';
	my @r;
	open FI,$mode,$filename or return undef;
	@r = <FI>;
	close FI;
	if(wantarray) {
		return @r;
	}
	else {
		return join("",@r);
	}
}
1;
 

