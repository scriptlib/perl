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

sub sc_from_file($) {
    my $fn=shift;
    my %result;
    return \%result unless($fn and -r $fn);
    unless(open FI,"<",$fn) {
        return \%result;
    }
    foreach my $line (<FI>) {
        chomp $line;
		next unless($line);
		next if($line =~ /^#/);
		next if($line =~ /^\s+$/);
		my @match = ($line =~ m/^\s*([^\s]+)\s*(.*?)\s*$/);
		next unless(@match);
		my $key = $match[0];
		my $value = $match[1];
		if($key =~ m/^(.+)_(\d+)$/) {
			$key = $1;
			my $idx = $2;
			if(defined $result{$key} and ref $result{$key}) {
			}
			elsif(defined $result{$key}) {
				$result{$key} = [$result{$key}];
			}
			else {
				$result{$key} = [];
			}
			$result{$key}[$idx] = $value;
		}
		else {
			$result{$key} = $value;
		}
    }
    close FI unless(ref $fn);
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
    foreach my $key (sort keys %UF) {
		my $value = $UF{$key};
		if(ref $value) {
			my $idx = 0;
			foreach(@{$value}) {
				print $fh $key . "_$idx    " . $_ . "\n";
				$idx++;
			}
		}
		else {
			print $fh "$key    $value\n"
		}
    }
    close $fh unless(ref $fn);
    return 1;
}
return 1;
