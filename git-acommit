#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::git_acommit;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
	action|a:s
	message|m:s
	all
	force|f
	verbose|v
	ignore-errors
	auto
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
my @gitarg = ();
push @gitarg,"-A" if($OPTS{all});
push @gitarg,"--force" if($OPTS{force});
push @gitarg,"--verbose" if($OPTS{verbose});
push @gitarg,"--ignore-errors" if($OPTS{'ignore-errors'});

sub run{
	print STDERR join(" ",@_),"\n";
	system(@_) == 0;
}
sub gitacommit {
	my $action = shift;
	my $cmds = shift;
	my @files = @_;
	return unless($cmds);

	if(ref $cmds) {
		foreach my $cmd (@{$cmds}) {
			if(ref $cmd) {
				run("git",@$cmd,@gitarg,"--",@files);
			}
			else {
				run("git",$cmd,@gitarg,"--",@files);
			}
		}	
	}
	else {
		run("git",$cmds,@gitarg,"--",@files);
	}
	my $message = $OPTS{message};
	if(!$message) {
		my $count = @files;
	
		if($count > 2) {
			$message = "$action $count files:\n\n\t";
			$message .= join("\n\t",@files);
		}
		elsif($count == 2) {
			$message = "$action files:" . join(",",@files);
		}
		else {
			$message = "$action file: $files[0]";
		}
	}
	run(qw/git commit -m/,$message);
}

my $action = $OPTS{action} || 'Update';
my $cmd = 'add';
$cmd = 'rm' if((lc($action) eq 'delete'));
my $action_done = $action;
$action_done =~ s/e?$/ed/;
my $message = $OPTS{message} ? $OPTS{message} . "\n\n" : '';


my @default;
my @modified;
my @deleted;
my @new;

if($OPTS{auto}) {
	open FI,"-|",qw/git status --porcelain/ or die("Error run <git status --porcelain>: $!\n");	
	while(<FI>) {
		chomp;
		next unless(m/^(..)\s(.+)$/);
		my $c = $1;
		my $file = $2;
		$file =~ s/^"(.+)"$/$1/;
		if($c eq ' M' || $c eq 'A ') {
			push @modified,$file;
		}
		elsif($c eq ' D' || $c eq 'AD') {
			push @deleted,$file;
		}
		elsif($c eq '??') {
			push @new,$file;
		}
		else {
			print STDERR "Ignored unknown file: $file\n";
		}
	}
}
else {
	@default = @ARGV;
}

&gitacommit('Update','add',@modified) if(@modified);
&gitacommit('Delete',[
		['rm','--cached','-f'],
		['rm','-f',],
	],@deleted) if(@deleted);
&gitacommit('Add','add',@new) if(@new);
&gitacommit($action,$cmd,@default) if(@default);


__END__

=pod

=head1  NAME

git-acommit - Git add and commit

=head1  SYNOPSIS

git-acommit [options] files...

=head1  OPTIONS

=over 12

=item B<--action>,B<-a>

Specified the action, default to "Update".

=item B<--message>,B<-m>

Specified the message.

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

    2013-09-29 21:07  xiaoranzzz  <xiaoranzzz@Mainstream>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@Mainstream>

=cut

#       vim:filetype=perl
