#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::bad_picdir;
use strict;
use warnings;
use File::Glob qw/bsd_glob/;
use MyPlace::Script::Message;
our $VERSION = 'v0.1';

my @OPTIONS = qw/
	help|h|? 
	manual|man
	test|t
    verbose|v:i
    action|a:s
	only-empty
	strict:i
	size:i
	files:i
	dest|D=s
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

my $SAY;
my %ACTIONS;
my $ACTION;
my %TESTS;
my $TEST;

sub get_opt {
	my $name = shift;
	if(defined $OPTS{$name}) {
		return $OPTS{$name};
	}
	else {
		my $default = shift;
		return $default;
	}
}

sub system_run {
	return system(@_) == 0;
}

sub say_warn {
	$SAY->warn(@_) if(@_ && $OPTS{verbose});	
}

sub say_err {
	$SAY->error(@_);
}
sub say_msg {
	if($OPTS{verbose}) {
		$SAY->message(@_) if(@_);
	}
}

sub output_emptydir {
	$ACTION->{do}(@_);
}
sub output_baddir {
	$ACTION->{do}(@_);
}
sub output_nopicdir {
	$ACTION->{do}(@_);
}

sub process_test {
	my $D = shift;
	say_msg ":$D ...\n";
	my $DH;
	my @subdirs;
	my @files;
	if(!opendir($DH,$D)) {
		say_err "OPEN DIRECTORY FAILED\n";
		return;
	}
	while(readdir $DH) {
		next if(m/^\.+\/*$/);
		my $entry = "$D/$_";
		if(-d $entry) {
			push @subdirs,$entry;
		}
		else {
			push @files,$entry;
		}
	}
	closedir $DH;
	if(@subdirs) {
		process_test($_) foreach(@subdirs);	
	}
	my $havesubdir = @subdirs ? 1 : 0;
	my $t = $TEST->{exec}($_,\@files,$havesubdir);
	my $a;
	if($t) {
		say_msg "\t$t.\n";
		$a=$ACTION->{do}($_,\@files,$havesubdir);
	}
	return $t,$a;
}

sub process_dir {
	my $D = shift;
	say_msg ":$D ...\n";
	my $DH;
	my @subdirs;
	my @files;
	if(!opendir($DH,$D)) {
		say_err "OPEN DIRECTORY FAILED\n";
		return;
	}
	while(readdir $DH) {
		next if(m/^\.+\/*$/);
		my $entry = "$D/$_";
		if(-d $entry) {
			push @subdirs,$entry;
		}
		else {
			push @files,$entry;
		}
	}
	closedir $DH;
	if(@subdirs) {
		foreach(@subdirs) {
			process_dir($_);
		}
	}
	elsif($OPTS{'only-empty'}) {
		if(@files and scalar(@files)>0) {
			say_msg "\t\t PASS TEST\n";
		}
		else {
			say_warn "\t\t EMPTY DIRECTORY\n";
			output_emptydir($D);
		}
	}
	elsif(@files) {
		my $goodfile;
		my $badfile;
		my $tested = 0;
		my $MIME_TYPE = "image/jpeg";
		foreach(@files) {
			if(m/\.[Jj][Pp][Ee]?[Gg]/) {
				$tested++;
				if($tested>$OPTS{files}) {
					last;
				}
				my $fsize = (stat($_))[7];
				if($fsize < $OPTS{size}) {
					say_warn "\t\t SMALL FILE. [$fsize<$OPTS{size}]\n";
					$badfile=1;
					last if($OPTS{strict});
					next;
				}
				my $mime = `file -i -b "$_"`;
				next unless($mime);
				chomp($mime);
				if($mime eq $MIME_TYPE) {
					say_warn "\t\t FAKE JPEG FILE. [$mime]\n";
					$badfile=1;
					last if($OPTS{strict});
					next;
				}
				$goodfile=1;
				#say_msg "[GOOD FILE]$_\n";
				last if(!$OPTS{strict});
			}
		}
		if($OPTS{strict} && $badfile) {
			output_baddir($D);
		}
		elsif(!($badfile || $goodfile)) {
			say_warn "\t\t NO PICTURE FILE.\n";
			output_nopicdir($D);
		}
		elsif(!$goodfile) {
			output_baddir($D);
		}
		else {
			say_msg "\t\t PASS TEST\n";
		}
	}
	else {
		say_warn "\t\t EMPTY DIRECTORY\n";
		output_emptydir($D);
	}
}


%ACTIONS = (
    'print'=>{
        'name'=>'print',
        'do'=>sub {
			print join("\n",@_),"\n" if(@_);
        },
		'check'=>sub {return 1},
    },
	'delete'=>{
		name=>'delete',
		'do'=>sub {
			foreach my $file(@_) {
				if($OPTS{test}) {
					say_msg("[TEST MODE] Deleting $file ...\n");
				}
				else {
					if($OPTS{verbose}) {
						system_run("rm","-frv","--",$file);
					}
					else {
						system_run("rm","-fr","--",$file);
					}
				}
			}
		},
		'check'=>sub {return 1},
	},
    'move'=>{
        'name'=>'move',
        'do'=>sub {
			my @files = @_;
			my $target = "$OPTS{dest}/";
			system_run('mkdir','--',$target) unless(-d $target || $OPTS{test});
            foreach my $file(@files) {
			    if($OPTS{test}) {
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
            say_err "Error: option --dest must be specified.\n";
            return;
        },
    },
);

%TESTS = (
	'badpic'=>{
		'exec'=>sub {
			my ($dir,$files,$havesubdir) = @_;
			return undef if($havesubdir);
			if(!($files || @{$files})) {
				return "Empty directory.";
			}
			foreach(@{$files}) {
			}
		}
	}
);

$OPTS{size} = get_opt("size",20*1024);
$OPTS{strict} = get_opt('strict',1);
$OPTS{action} = get_opt('action','print');
$OPTS{verbose} = get_opt('verbose',1);
$OPTS{files} = get_opt('files',4);
$SAY = MyPlace::Script::Message->new("Bad Picture Directory");
$ACTION = $ACTIONS{$OPTS{action}};

if($OPTS{files} < 1) {
	say_err("Option \"--files\" must large than ZERO\n");
	exit 3;
}

if(!$ACTION) {
	say_err("Action $OPTS{action} not defined\n");
	exit 2;
}
say_msg("Action: $ACTION->{name}\n");

if(!$ACTION->{check}()) {
	exit 1;
}

foreach(@ARGV) {
	next unless(-d $_);
	process_dir($_);
}
