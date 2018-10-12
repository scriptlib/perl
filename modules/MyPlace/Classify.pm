#!/usr/bin/perl -w
package MyPlace::Classify;

use strict;
use warnings;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw();
    @EXPORT_OK      = qw(read_rules set_options);
}
use MyPlace::Config::Array;
our %OPTS;

sub set_options {
	%OPTS = (%OPTS,@_);
}

sub read_rules {
    my $filelist = shift;
    my $dest = shift;
    my @rules;
    my @rule=();
	my @keyword;
	my @data;
	my $A = new MyPlace::Config::Array;
	foreach my $file (split(/\s*,\s*/,$filelist)) {
		my $RULE_FILE = $file;
		if(!-f $RULE_FILE) {
			$RULE_FILE .= ".rule";
		}
		if(!-f $RULE_FILE) {
			print STDERR "Rule <$file> not exists\n";
			next;
		}
		print STDERR "Rules reading from <$RULE_FILE>\n";
		$A->readfile($RULE_FILE);
		push @data, $A->get_data;
	}
	my $count = 0;
	foreach my $def (@data) {
		my @value = @$def;
		$_ = shift(@value);
        if(m/^#include\s+(.+)$/) {
			my $r = read_rules($1,$dest);
            push @rules,@$r if($r);
			next;
        }
        elsif(m/^#dest\s+(.+)$/) {
            my $d = $1;
            if($d =~ m/^\//) {
                $dest = $d;
            }
            else {
                $dest = "$dest/$d"
            }
			next;
        }
        elsif(m/^\/\//) {
			next;
        }
		elsif(m/\s*,\s*/) {
			my @a = split(/\s*,\s*/,$_);
			$_ = shift @a;
			unshift(@value,@a);
		}
		
		#Translate values like "AB CD EF" to "AB[-~_\.\s]*CD[-~_\.\s]*EF
		my %r;
		$r{name} = $_;
		$r{dest} = $dest;
		$r{keyword} = [];
		foreach(@value) {
			if(m/^<[^>]+>\s*(.+)\s*$/) {
				push @{$r{keyword}},$1;
			}
			else {
				push @{$r{keyword}},$_;
			}
		}
		@value = map {s/\\-|\\_/[-~_\.\\s]*/g;$_} @value;
		@value = map {s/\s+/[-~_\.\\s]+/g;$_} @value;
		if(m/^<SN>(.+)$/) {
			$r{name} = $1;
			$r{exp} = join("|","\\b$1\[-~_\\.\\s]*\\d+",@value);
		}
		elsif(m/^<TI>(.+)$/) {
			my $name = $1;
			$r{name} = $name;
			$name =~ s/\\-|\\_|\s+/[-~_\.\\s]*/g;
			$r{exp} = join("|",$name,@value);
		}
		elsif(m/^<W>(.+?)\s*$/) {
			my $name = $1;
			$r{name} = $name;
			$name =~ s/\\-|\\_|\s+/[-~_\.\\s]*/g;
			$name = "\\b$name\\b";
			$r{exp} = join("|",$name,@value);
		}
		elsif($_ =~ m/^</) {
			s/^<//;
			$r{name} = $_;
			$r{exp} = join('|',@value);
			$r{exclude_name} = 1;
		}
		elsif($_ =~ m/^-(.+)$/) {
			$r{name} = $1;
			$r{exp} = join('|',@value);
			$r{exclude_name} = 1;
		}
		else {
			s/^\/</</;
			#s/([\[\]\(\)\@\$\*\?\^])/\\\\$1/g;
			s/\s+/[-~_\.\\s]*/g;
			#s/^#+//;
			$_ = '\b' . $_ . '\b' if($OPTS{word});
			$r{exp} = join('|',$_,@value);
		}
		push @rules,\%r;
		$count++;
		print STDERR "\rRules count : $count";
	}
	print STDERR "\n";
	return \@rules;
}


1;
