#!/usr/bin/perl -w
package MyPlace::SimpleConfig;
use strict;
use warnings;
BEGIN {
    use Exporter ();
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw();
    @EXPORT_OK      = qw(sc_from_file sc_parse_line sc_to_file);
}

sub sc_parse_line($) {
    my $line=shift;
    return undef if(!$line or $line =~ /^#/);
    my @match = $line =~ m/^\s*([^\s]+)\s*(.*)\s*$/;
    return undef unless(@match);
    return ($match[0],[ split(/\s+/,$match[1]) ]);
}

sub sc_from_file($) {
    my $fn=shift;
    my %result;
    return \%result unless($fn and -r $fn);
    unless(open FI,"<",$fn) {
        return \%result;
    }
    while(<FI>) {
        chomp;
        my ($key,$ref_value)=sc_parse_line($_);
        next unless($key);
        $result{$key}=$ref_value;
    }
    return \%result;
}
sub sc_to_file($$) {
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
        print $fh $_;
        foreach my $value (@{$UF{$_}}) { 
            print $fh " $value";
#            print $fh " ",($value =~ m/[^_\w]/ ? "\"$value\"" :$value);
        }
        print $fh "\n";
    }
    close $fh unless(ref $fn);
    return 1;
}
return 1;
