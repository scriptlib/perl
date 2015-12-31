#!/usr/bin/perl -w
package MyPlace::Script::Src2Help;
use strict;
use warnings;

BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT_OK      = qw(&print_help &get_source_info &info_to_text &convert_source);
    $EXPORT_TAGS{all} = [ qw(&print_help &get_source_info &info_to_text &convert_source) ];
}

sub get_source_info {
    my $fn=shift;
    my $DEFAULTOPT=shift;
    $DEFAULTOPT="" unless($DEFAULTOPT);
    unless(-r $fn and open TEXT,"<",$fn) {
        print STDERR "File not accessible: $fn\n";
        return undef;
    }
    my %HELPVAR;
    while(<TEXT>) {
        last unless(/^#/ or 
                    /^my\s*\$APP/ or 
                    /^use/ or
                    /^APP/);
        if( /^#*(\w+):\s*(.*)\s*$/ or 
            /^my\s*\$(APP\w+)\s*=\s*"*(.*)"*\s*;\s*$/ or
            /^#*(\w+)="(.*)"\s*/ or
            /^#*(\w+)=(.*)\s*/) {
            my $name=$1;
            my $result=$2;
            $result =~ s/\\t/\t/g;
            $result =~ s/\\n/\n/g;
            push @{$HELPVAR{$name}},$result;
        }
    }
    close(TEXT);
    if ($HELPVAR{APPOPTION}) {
        push @{$HELPVAR{APPOPTION}},$DEFAULTOPT;
    }
    else {
        push @{$HELPVAR{APPOPTION}},$DEFAULTOPT;
    }
	push @{$HELPVAR{APPNAME}},$fn unless($HELPVAR{APPNAME});
    return \%HELPVAR;
}

sub info_to_text($) {
    my $href=shift;
    return undef unless($href and ref $href);
    my %HELPVAR=%{$href};
    my @result;
    return undef unless(%HELPVAR);
    push(@result,$HELPVAR{APPNAME}->[0]) if($HELPVAR{APPNAME});
    push(@result," V" ,$HELPVAR{APPVER}->[0]) if($HELPVAR{APPVER});
    push(@result,"\n");
	if($HELPVAR{APPDESC}) {
		foreach(@{$HELPVAR{APPDESC}}) {
			push @result,"\t",$_,"\n";
		}
	}
    if ($HELPVAR{APPAUTHOR}) {
        push(@result,"\t- by " . $HELPVAR{APPAUTHOR}->[0]); 
        push(@result,", " . $HELPVAR{APPDATE}->[0]) if($HELPVAR{APPDATE});
        push(@result,"\n");
    }
	if($HELPVAR{APPUSAGE}) {
		push @result,"Usage:\n";
		foreach(@{$HELPVAR{APPUSAGE}}) {
			push @result,"\t",$HELPVAR{APPNAME}->[0]," $_\n";
		}
	}
    if($HELPVAR{APPOPTION}) {
        push(@result,"Option:\n  ");
	    my @HELPOPT;
		foreach(@{$HELPVAR{APPOPTION}}) {
        	foreach(split(/\|/,$_)) {
            	if(m/^\s*([^:]+)\s*:\s*(.+)\s*$/) {
                	my $c=$1;
	                my $str=$2;
    	            #$c = "-" . $c if($c !~ /^-/);
        	        push(@HELPOPT,{opt=>$c,text=>$str});
            	}
        	}
		}
        foreach (@HELPOPT) {
            push @result,sprintf("\t%-10s\t%s\n",$_->{opt},$_->{text});
        }
    }
	if($HELPVAR{APPEXAMPLE}) {
		push @result,"Example:\n";
		foreach(@{$HELPVAR{APPEXAMPLE}}) {
			push @result,"\t$_\n";
		}
	}
    my $StdKey=qr/^APPNAME|APPVER|APPDESC|APPOPTION|APPEXAMPLE|APPUSAGE|APPDATE|APPAUTHOR$/;
    foreach(keys %HELPVAR) {
        next if($_ =~ $StdKey);
		push @result,$_,":\n";
		foreach(@{$HELPVAR{$_}}) {
				push @result,"\t$_\n";
		}
    }
    return \@result;
}

sub convert_source {
    my $info=get_source_info(@_);
    return undef unless($info and ref $info);
    return info_to_text($info);
}


sub print_help {
    my $text=&convert_source(@_);
    return undef unless(defined $text);
    print @{$text};
    return 1;
}

return 1;
