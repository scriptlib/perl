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
                elsif(m/^#/) {
                }
                elsif($_ and (!@rule)) {
                    push @rule,$_;
                }
                elsif($_) {
                    push @rule,$_;
                }
                elsif(@rule) {
                    push @rules,{
                        'name'=>$rule[0],
                        'exp'=>join('|',@rule),
                        'dest'=>$dest,
                    };
                    @rule=();
                }
	}
        if(@rule) {
            push @rules,{
                'name'=>$rule[0],
                'exp'=>join('|',@rule),
                'dest'=>$dest,
            };
        }
    close $FI;
    return \@rules;
}

my %Actions = (
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
	    system_run('mkdir','--',$target) unless(-d $target || $TESTMODE);
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
            return 1 if($OPTS{'dest'});
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
		'case'=>'0',
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
    if($TEST_METHOD->{test}->($file,$rule->{'exp'})) {
        return $file,$rule;
    }
    return;
}

sub classify {
    my $file = shift;
    my $rule = shift;
    $rule->{name} =~ s/^\^+//;
    $rule->{name} =~ s/\$+$//;
    if(test($file,$rule)) {
        $CLASSIFIED{$file} = 1;
        $rule->{files}=[] if(!$rule->{files});
        push @{$rule->{files}},$file;
        print STDERR "Classify [",$rule->{name},"] $file\n" if($OPTS{verbose});
    #    do_action($file,$rule);
        return $file,$rule;
    }
    elsif($OPTS{debug}) {
        print STDERR "Classify [",'FAILED',"] $file\n";
    }
    return;
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
    foreach(@$rules) {
        process_rule($files,$_);
    }
    foreach my $rule (@$rules) {
        if($rule->{files} && @{$rule->{files}}) {
            print STDERR "Class [$rule->{name}] matches " . scalar(@{$rule->{files}}) . " file(s).\n";
            do_action($rule->{files},$rule);
        }
        else {
            print STDERR "Class [$rule->{name}] matches nothing!\n" if($OPTS{debug});
        }
    }
    #foreach(@$files) {
    #    process_file($_,$rules);
    #}
}


if(@ARGV) {
    @files = @ARGV;
}
else {
    $OPTS{verbose} && print STDERR "Please input filenames:\n";
    while(<STDIN>) {
        chomp;
        push @files,$_;
    }
}
$DEST = $OPTS{'dest'} || '.';
$METHOD = $OPTS{'by'} || 'text';
$RULE_FILE = $OPTS{'rule'} || 'classify.rule';
$TESTMODE = $OPTS{'test'} || '';
my $ACTION_NAME=$OPTS{'action'} || 'print';
$ACTION=$Actions{$ACTION_NAME};

if(! -d $DEST) {
	die("Error $DEST not exsits, or not a directory.\n");
}
if(! -f $RULE_FILE) {
	die("Error: Rule file $RULE_FILE not exist, or not a file.\n");
}
if(!@files) {
	die("Error: Nothing to do.\n");
}
if(!$ACTION) {
        die("Error: Action $ACTION_NAME not defined.\n");
}
if(!$ACTION->{check}->()) {
        die();
}
$RULES=read_rules($RULE_FILE);
dumpdata($RULES,'rules');

$TEST_METHOD = $TestMethod{$METHOD};
if(!$TEST_METHOD) {
	die("Error: test method $METHOD not defined\n");
}
print STDERR "Test by $METHOD\n" if($OPTS{'debug'});

#print STDERR $TEST_METHOD->('a','.+a') ? 'TRUE' : 'FALSE',"\n";
#dumpdata($TEST_METHOD,'TEST_METHOD');

#dumpdata(\@files,'Operation target');


process(\@files,$RULES);


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

  --by name
	By filename
  --by content
	By file content

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
