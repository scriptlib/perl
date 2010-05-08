#!/usr/bin/perl -w

use strict;
use warnings;

BEGIN {
    use Exporter ();
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT_OK      = qw(&not_root &is_root &sudo_invoke_this &sudo_invoke);
}

sub is_root() {
    return ($ENV{USER} eq "root");
}
sub not_root() {
    return not &is_root;
}
sub sudo_invoke {
    my $argv = "";
    $argv = " \"" . join("\" \"",@_) . "\"" if(@ARGV);
    print STDERR "invoke",$argv," as superuser\n";
    return system("sudo",@_);
}
sub sudo_invoke_this {
    return sudo_invoke($0,@ARGV);
}

return 1;
