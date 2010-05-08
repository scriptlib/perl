#!/usr/bin/perl -w
package xrzReader;
use strict;
use warnings;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw($INC_ZIM $INC_XRZ);
}

our $INC_ZIM="";
our $INC_XRZ="";
#my @OTHER_INC;

foreach(@INC) {
    if($INC_XRZ && $INC_ZIM) {
        last;
    }
    elsif(!/^\//) {
#        push @OTHER_INC,$_;
    }
    elsif(-f "$_/xrzReader.pm") {
        $INC_XRZ=$_;
    }
    elsif(-f "$_/Zim.pm") {
        $INC_ZIM=$_;
    }
    else {
#        push @OTHER_INC,$_;
    }
}

die("Zim module directory not found!\n") unless($INC_ZIM);
die("xrzReader module directory not found!\n") unless($INC_XRZ);
#warn "Zim module located at:$INC_ZIM\n";
#warn "xrzReader module located at:$INC_XRZ\n";

1;


