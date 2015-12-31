#!/usr/bin/perl -w
use strict;
use warnings;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT	        = qw(js_escape js_unescape);
    @EXPORT_OK      = qw(js_escape js_unescape);
}


sub js_unescape {
    foreach(@_) {
        $_ =~ s/%u([0-9a-f]+)/chr(hex($1))/eig;
        $_ =~ s/%([0-9a-f]{2})/chr(hex($1))/eig;
    }
	if(wantarray) {
		return @_;
	}
	else {
		return join("",@_);
	}
}

sub js_escape {
  my $str = shift || '';
  $str =~ s/([^\n()?%a-zA-Z0-9])/sprintf("%%u%04X",ord($1))/eg;
  return $str;
}


1;

