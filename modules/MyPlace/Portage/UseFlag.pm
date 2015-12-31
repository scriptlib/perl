#!/usr/bin/perl -w
package MyPlace::Portage::UseFlag;
use strict;
use warnings;
BEGIN {
    use Exporter ();
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw();
    @EXPORT_OK      = qw(useflag_from_file useflag_parse_line useflag_to_file);
}

sub useflag_parse_line($) {
    my $line=shift;
    return undef if(!$line or $line =~ /^#/);
    my @match = $line =~ m/^\s*([^\s]+)\s+(.*)\s*$/;
    return undef unless(@match);
    return ($match[0],split(/\s+/,$match[1]));
}

sub useflag_from_file($) {
    my $fn=shift;
    return undef unless($fn and -r $fn);
    unless(open FI,"<",$fn) {
        print STDERR "$!\n";
        return undef;
    }
    my %result;
    while(<FI>) {
        chomp;
        my @pkg=&useflag_parse_line($_);
        next unless(@pkg and $pkg[0]);
        my $name = shift @pkg;
        $result{$name}=\@pkg;
    }
    return \%result;
}
sub useflag_to_file($$) {
    my $fn=shift;
    return undef unless($fn);
    my %UF=%{shift @_};
    my $fh;
    if(ref $fn) {
        $fh=$fn
    }
    else {
        open $fh,">",$fn or return undef;
    }
    foreach(sort keys %UF) {
        my $line = $UF{$_} ? join(" ",@{$UF{$_}}) : "";
        print $fh $_," ",$line,"\n";
    }
    close $fh unless(ref $fn);
    return 1;
}
return 1;
