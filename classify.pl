#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::classify;
use strict;
our $VERSION = 'v0.1';


my @OPTIONS = qw/
	help|h|? 
	manual|man
	by|b:s
	rule|r:s
	dest|d:s
	test|t
    verbose|v
    debug
    action|a:s
	prefix=s
	suffix=s
	dump
/;
my %OPTS;
if(@ARGV)
{
    require Getopt::Long;
    Getopt::Long::GetOptions(\%OPTS,@OPTIONS);
}
else {
	$OPTS{'help'} = 1;
}
if($OPTS{'help'} or $OPTS{'manual'}) {
	require Pod::Usage;
	my $v = $OPTS{'help'} ? 1 : 2;
	Pod::Usage::pod2usage(-exitval=>$v,-verbose=>$v);
    exit $v;
}


use Cwd qw/getcwd/;

my (
    @files,$DEST,
    $RULES,$TESTMODE,
    $TEST_METHOD,$METHOD,
    $RULE_FILE,%CLASSIFIED,
    $ACTION,
);

#DEBUG
use Data::Dumper;
sub dumpdata {
        $OPTS{debug} or return;
	my $var = shift;
	my $name = (shift @_) || 'noname';
	print STDERR Data::Dumper->Dump([$var],[$name]);
}

sub read_rules {
    my $RULE_FILE = shift;
    my $dest = (shift @_) || $DEST;
    my @rules;
    my @rule=();
	my @keyword;
    open my $FI,'<',$RULE_FILE or die("$!\n");
	while(<$FI>) {
		chomp;
		s/^\s+//g;
		s/\s+$//g;
                if(m/^#include\s+(.+)$/) {
                    my $r = read_rules($1,$dest);
                    push @rules,@$r if($r);
                }
                elsif(m/^#dest\s+(.+)$/) {
                    my $d = $1;
                    if($d =~ m/^\//) {
                        $dest = $d;
                    }
                    else {
                        $dest = "$dest/$d"
                    }
                }
                elsif(m/^\s*\/\//) {
                }
                elsif($_ and (!@rule)) {
                    push @rule,$_;
					s/([\[\]\(\)\@\$\*\?\^])/\\\\$1/g;
					s/\s+/[-_\\s]*/g;
					s/^#+//;
					push @rule,$_;
                }
                elsif($_) {
                    push @rule,$_;
					push @keyword,$_;
                }
                elsif(@rule) {
                    push @rules,{
                        'name'=>shift(@rule),
                        'exp'=>join('|',@rule),
                        'dest'=>$dest,
						'keyword'=>[@keyword],
                    };
                    @rule=();
					@keyword=();
                }
	}
        if(@rule) {
            push @rules,{
                'name'=>shift(@rule),
                'exp'=>join('|',@rule),
                'dest'=>$dest,
				'keyword'=>[@keyword],
            };
        }
    close $FI;
	return \@rules;
}

my %Actions = (
	'keyword'=>{
		'name'=>'keyword',
		'do'=>sub {
			my ($files,$rule) = @_;
			my $target = $rule->{dest} . '/' . $rule->{name} . '/'; 
		    system_run('mkdir','-pv','--',$target) unless(-d $target || $TESTMODE);
			print STDERR "For [" . $rule->{name},"]\n";
			my @prog = ();
			push @prog,split(/\s+/,$OPTS{prefix}) if($OPTS{prefix});
			@prog = (qw/echo/) unless(@prog);
			my @suf = ();
			push @suf,split(/\s+/,$OPTS{suffix}) if($OPTS{suffix});
			print STDERR "Execute @prog ...\n" if(@prog);
			my @keywords = ($rule->{name});
			push @keywords, @{$rule->{keyword}} if($rule->{keyword});
			my $CWD = getcwd;
			chdir $target;
			foreach my $key (@keywords) {
				print STDERR "    Processing [" . $rule->{name} . "/$key] ...\n";
				system(@prog,$key,@suf);
			}
			chdir $CWD;
		},
		'check'=>sub {
			return 1;
		},
		'NOFILES'=>1,
	},
    'print'=>{
        'name'=>'print',
        'do'=>sub {
            my ($files,$rule)=@_;
            print $rule->{name},"\n";
            print join("\n",@$files),"\n";
            print "\n";
        },
        'check'=>sub {
            return 1;
        },
    },
    'move'=>{
        'name'=>'move',
        'do'=>sub {
            my ($files,$rule)=@_;
	    my $target = $rule->{dest} . '/' . $rule->{name} . '/'; 
	    system_run('mkdir','-pv','--',$target) unless(-d $target || $TESTMODE);
            foreach my $file(@$files) {
		    if($TESTMODE) {
		        print STDERR "\t[TEST MODE] Moving $file to $target\n"
		    }
		    elsif(!-e $file) {
		        print STDERR "\tError: $file not exist.\n"
		    }
		    else {
				print STDERR "[$target] <<< $file\n";
		        if($OPTS{verbose}) {
		            system_run('mv','-v','--',$file,$target);
		        }
		        else {
		            system_run('mv','--',$file,$target);
		        }
		    }
            }
        },
        'check'=>sub {
            return 1 if($OPTS{'dest'} || $DEST);
            print STDERR "Error: option --dest must be specified.\n";
            return;
        },
    },
);

my %TestMethod;

%TestMethod = (
	'text'=>{
		'name'=>'text',
		'test'=>sub {
			my $left = shift;
			my $right = shift;
			return ($TestMethod{text}->{case}) ? ($left =~ $right) : ($left =~ /$right/i) ;
		},
		'case'=>0,
	},
	'filename'=>{
		'name'=>'filename',
		'_cache'=>{},
		'test'=>sub {
			my $left = shift;
			my $right = shift;
			my $a = $TestMethod{filename}->{_cache}->{$left};
			if($a) {
				$left = $a;
			}
			else {
				$a = $left;
				$a =~ s/^.+[\/\\]+//;
				$TestMethod{filename}->{_cache}->{$left} = $a;
				$left = $a;
			}
			return $TestMethod{text}->{test}->($left,$right);
		},
	},
	'filecontent'=>{
	},
	'files'=>{
		'name'=>'Count files in directory',
		'test'=>sub {
			my $dir = shift;
			my $size = shift;
			if(opendir(my $dh,$dir)) {
				my $count = 0;
				while(readdir $dh) {
					#print STDERR "$_\n";
					$count++;
				}
				close $dh;
				$count -=2;
				if($count > $size) {
					return 1,">";
				}
				elsif($count == $size) {
					return 2,"=";
				}
				else {
					return 3,"<";
				}
			}
			else {
				return undef,"error",$!;
			}
		},
	},
	'imagesdir'=>{
		'name'=>'Images directory',
		'test'=>sub {
			my $dir = shift;
			my $exp = shift;
			my $size = 0;
			if($dir =~ m/[（\[【](\d+)[Pp][】\］）]/) {
				$size = $1;
			}
			elsif($dir =~ m/_(\d+)[Pp]$/) {
				$size = $1;
			}
			my ($status,$sign,$msg);
			if($size < 1) {
				$status = undef;
				$sign="error";
				$msg = "Directory Size Property Unknown.";
			}
			else {
				($status,$sign,$msg) = $TestMethod{files}->{test}->($dir,$size);
			}
			if($sign =~ m/$exp/) {
				if($status) {
					return 1,"$sign $size";
				}
				else {
					return 1,"Error: $msg";
				}
			}
			else {
				return undef;
			}
		}
	},
);
sub system_run {
    $OPTS{'debug'} && print join(" ",@_),"\n";
    return system(@_)==0;
}
sub do_action {
    my $files = shift;
    my $rule = shift;
    return $ACTION->{do}->($files,$rule);
}

sub test {
    my $file = shift;
    my $rule = shift;
    return $TEST_METHOD->{test}->($file,$rule->{'exp'});
}

sub classify {
    my $file = shift;
    my $rule = shift;
#    $rule->{name} =~ s/^\^+//;
#    $rule->{name} =~ s/\$+$//;
	my($status,$msg) = test($file,$rule);
    if($status) {
        $CLASSIFIED{$file} = 1;
        $rule->{files}=[] if(!$rule->{files});
        push @{$rule->{files}},$file;
        print STDERR "Classify [",$rule->{name},($msg ? ": $msg" : ""),"] $file\n" if($OPTS{verbose});
        return $file,$rule;
    }
	else {
	    if($OPTS{debug} || $OPTS{verbose}) {
			print STDERR "Classify [",'FAILED',($msg ? ": $msg" : ""),"] $file\n";
	    }
		return;
	}
}

sub process_nofiles {
	my $files = shift;
	my $rules = shift;
	my @match = ();
	if($files and @$files) {
		foreach my $rule(@$rules) {
			foreach my $file(@files) {
				if($rule->{name} =~ /$file/i) {
					push @match,$rule;
				}
			}
		}
	}
	else {
		@match = (@$rules);
	}
	foreach my $rule(@match) {
		do_action($files,$rule);
	}
}

sub process_file {
    my $file = shift;
    my $rules = shift;
    foreach my $rule(@$rules) {
        classify($file,$rule);
    }
}

sub process_rule {
    my $files = shift;
    my $rule = shift;
    foreach my $file(@$files) {
        next if($CLASSIFIED{$file});
        classify($file,$rule);
    }
}

sub process {
    my $files = shift;
    my $rules = shift;
    foreach my $rule (@$rules) {
        process_rule($files,$rule);
    }
#	use Data::Dumper;print STDERR Dumper($rules);
    foreach my $rule (@$rules) {
        if($rule->{files} && @{$rule->{files}}) {
            print STDERR "Class [$rule->{name}] matches " . scalar(@{$rule->{files}}) . " file(s).\n";
            do_action($rule->{files},$rule);
        }
        else {
            print STDERR "Class [$rule->{name}] matches nothing!\n" if($OPTS{debug} || $OPTS{verbose});
        }
    }
    #foreach(@$files) {
    #    process_file($_,$rules);
    #}
}


$DEST = $OPTS{'dest'} || '.';
$METHOD = $OPTS{'by'} || 'text';
$RULE_FILE = $OPTS{'rule'} || 'classify.rule';
$TESTMODE = $OPTS{'test'} || '';
my $ACTION_NAME=$OPTS{'action'} || 'print';
$ACTION=$Actions{$ACTION_NAME};

if($OPTS{dump}) {
	$RULES=read_rules($RULE_FILE);
	my $count=0;
	foreach my $rule (@$RULES) {
		$count++;
		print STDERR "NAME:  ",$rule->{name},"\n";
		print STDERR "  EXPS: ",$rule->{exp},"\n";
	}
	print STDERR "Totally " . ($count >1 ? "$count rules" : "$count rule") . " dumped\n";
	exit 0;
}


if(! -d $DEST) {
	die("Error $DEST not exsits, or not a directory.\n");
}
if(! -f $RULE_FILE) {
	die("Error: Rule file $RULE_FILE not exist, or not a file.\n");
}

if(@ARGV) {
    @files = @ARGV;
}
if(!$ACTION) {
        die("Error: Action $ACTION_NAME not defined.\n");
}
if(!$ACTION->{check}->()) {
        die();
}

$RULES=read_rules($RULE_FILE);
dumpdata($RULES,'rules') if($OPTS{debug});

$TEST_METHOD = $TestMethod{$METHOD};
if(!$TEST_METHOD) {
	die("Error: test method $METHOD not defined\n");
}
print STDERR "Test by $METHOD\n" if($OPTS{'debug'});

#print STDERR $TEST_METHOD->('a','.+a') ? 'TRUE' : 'FALSE',"\n";
#dumpdata($TEST_METHOD,'TEST_METHOD');

#dumpdata(\@files,'Operation target');

if($ACTION->{NOFILES}) {
	exit process_nofiles(\@files,$RULES);
}

if(!@files) {
    print STDERR "Read files list from standard input...\n";
    while(<STDIN>) {
        chomp;
        push @files,$_;
    }
}

if(!@files) {
	die("Error: Nothing to do.\n");
}

exit process(\@files,$RULES);


__END__

=pod

=head1  NAME

classify - PERL script

=head1  SYNOPSIS

classify [options] filenames...

=head1  OPTIONS

=item B<--dest>

Specify destination directory

=item B<--by>

Specify method for classifing.

  --by text
	Testing text input

  --by filename
	Testing filename

  --by filecontent
	Testing filecontent

  --by files
	Testing files count

  --by imagesdir
	Testing images directory

=item B<--rule>

Specify file of rules

=item B<--version>

Print version infomation.

=item B<-h>,B<--help>

Print a brief help message and exits.

=item B<--manual>,B<--man>

View application manual

=item B<--edit-me>

Invoke 'editor' against the source

=back

=head1  DESCRIPTION

___DESC___

=head1  CHANGELOG

    2013-09-25 01:50  xiaoranzzz  <xiaoranzzz@Mainstream>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@Mainstream>

=cut

#       vim:filetype=perl
