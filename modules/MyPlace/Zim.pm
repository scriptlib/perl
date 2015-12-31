#!/usr/bin/perl -w
package MyPlace::Zim;
use strict;
use warnings;
use Zim::Store;

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
    @EXPORT         = qw(&get_filename);
    @EXPORT_OK      = qw();
}
return 1;

sub get_filename($) {
    my $oldname=shift;
    return Zim::Store->clean_name($oldname,'RELATIVE');
}
