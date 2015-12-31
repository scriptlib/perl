#!/usr/bin/perl -w
package MyPlace::Classifier;
use strict;
use warnings;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw();
    @EXPORT_OK      = qw(&AddTestMethod &AddAction);
}
my %Actions = (
    'print'=>{
        'name'=>'print',
        'do'=>sub {
            my ($self,$files,$rule)=@_;
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
            my ($self,$files,$rule)=@_;
	    my $target = $rule->{dest} . '/' . $rule->{name} . '/'; 
	    $self->system_run('mkdir','--',$target) unless(-d $target || $TESTMODE);
            foreach my $file(@$files) {
		    if($TESTMODE) {
		        print STDERR "\t[TEST MODE] Moving $file to $target\n"
		    }
		    elsif(!-e $file) {
		        print STDERR "\tError: $file not exist.\n"
		    }
		    else {
				print STDERR "[$target] <<< $file\n";
		        if($self->{Options}->{verbose}) {
		           $self->system_run('mv','-v','--',$file,$target);
		        }
		        else {
		            $self->system_run('mv','--',$file,$target);
		        }
		    }
            }
        },
        'check'=>sub {
			my $self = shift;
            return 1 if($self->{Options}->{'dest'});
            print STDERR "Error: option --dest must be specified.\n";
            return;
        },
    },
);

my %TestMethod = (
	'text'=>{
		'name'=>'text',
		'test'=>sub {
			my $self = shift;
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
			my $self = shift;
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
			return $TestMethod{text}->{test}->($self,$left,$right);
		},
	},
	'filecontent'=>{
	},
	'files'=>{
		'name'=>'Count files in directory',
		'test'=>sub {
			my $self = shift;
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
			my $self = shift;
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
				($status,$sign,$msg) = $TestMethod{files}->{test}->($self,$dir,$size);
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
my %$CLASSIFIED;

sub new {
	my $class = shift;
	return bless {@_},$class;
}

sub system_run {
	my $self = shift;
	$self->{Options}->{'debug'} && print join(" ",@_),"\n";
    return system(@_)==0;
}
sub do_action {
	my $self = shift;
    my $files = shift;
    my $rule = shift;
    return $ACTION->{do}->($self,$files,$rule);
}

sub test {
	my $self = shift;
    my $file = shift;
    my $rule = shift;
    return $TEST_METHOD->{test}->($self,$file,$rule->{'exp'});
}


sub classify {
	my $self = shift;
    my $file = shift;
    my $rule = shift;
#    $rule->{name} =~ s/^\^+//;
#    $rule->{name} =~ s/\$+$//;
	my($status,$msg) = $self->test($file,$rule);
    if($status) {
        $CLASSIFIED{$file} = 1;
        $rule->{files}=[] if(!$rule->{files});
        push @{$rule->{files}},$file;
        print STDERR "Classify [",$rule->{name},($msg ? ": $msg" : ""),"] $file\n" if($self->{Options}->{verbose});
        return $file,$rule;
    }
	else {
	    if($self->{Options}->{debug} || $self->{Options}->{verbose}) {
			print STDERR "Classify [",'FAILED',($msg ? ": $msg" : ""),"] $file\n";
	    }
		return;
	}
}

sub process_rule {
	my $self = shift;
    my $files = shift;
    my $rule = shift;
    foreach my $file(@$files) {
        next if($CLASSIFIED{$file});
        $self->classify($file,$rule);
    }
}

sub process {
	my $self = shift;
    my $files = shift;
    my $rules = shift;
    foreach my $rule (@$rules) {
        $self->process_rule($files,$rule);
    }
    foreach my $rule (@$rules) {
        if($rule->{files} && @{$rule->{files}}) {
            print STDERR "Class [$rule->{name}] matches " . scalar(@{$rule->{files}}) . " file(s).\n";
            $self->do_action($rule->{files},$rule);
        }
        else {
            print STDERR "Class [$rule->{name}] matches nothing!\n" if($self->{Options}->{debug} || $self->{Options}->{verbose});
        }
    }
}


1;
