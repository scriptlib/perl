#!/usr/bin/perl -w
package MyPlace::Script::Debug;
use strict;
use warnings;
BEGIN {
    sub debug_print {
        return unless($ENV{XR_PERL_MODULE_DEBUG});
        print STDERR __PACKAGE__," : ",@_;
    }
    &debug_print("BEGIN\n");
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw(dump_var);
    @EXPORT_OK      = qw();
}

sub dump_var {
    use Data::Dumper;
    foreach(@_) {
        if(ref $_) {
            print STDERR Dumper($_),"\n";
        }
        else {
            print STDERR Dumper(\$_),"\n";
        }
    }
}
return 1;
