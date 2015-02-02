#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::unln;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
	notdry
	dest|dst=s
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

use File::Spec::Functions qw/catfile splitpath/;
use Cwd qw/getcwd/;

my $FH_LOG;
sub logfile {
	return unless($FH_LOG);
	print $FH_LOG @_,"\n";
}

sub readfile {
	my $file = shift;
	return unless(-e $file);
	return unless(-l $file);
	return readlink($file);
}

sub movefile {
	my $sym = shift;
	my $dst = shift;
	my $link_to = readfile($sym);
	if(!$link_to) {
		print STDERR " Error not a symbolic link file:$sym\n";
		logfile("[EF]$sym");
		return;
	}
	my (undef,$symdir,$symname) = splitpath($sym);
	my (undef,$lnkdir,$lnkname) = splitpath($link_to);

	my $kwd = getcwd;
	my $target = $symname;

	if($symdir and (!chdir($symdir))) {
		print STDERR " Error CHDIR $symdir:$!\n";
		logfile("[EC]$symdir");
		return;
	}

	if($dst) {
		$target = catfile($dst,$symname);
		if(-e $target) {
			print STDERR " Error TARGET exists:$!\n";
			chdir $kwd;
			logfile("[EE]$target");
			return;
		}
	}
	
		print STDERR "[XX] $symname ...\n";
	if($OPTS{notdry}) {
		if(!unlink $symname) {
			print STDERR " Error remove $symname:$!\n";
			chdir $kwd;
			logfile("[FD]$sym");
			return;
		}
		else {
			logfile("[D]$sym");
		}
	}
	else {
		print STDERR " unlink $sym\n";
	}


		print STDERR "[<-] $target\n\t$link_to ...\n";
	if($OPTS{notdry}) {
		if(system('mv','--',$link_to,$target)!=0) {
			print STDERR " Error move $link_to -> [$target]:$!\n";
			logfile("[FM]$link_to\t$target");
			chdir $kwd;
			return;
		}
		else {
			logfile("[M]$link_to\t$target");
		}
	}
	else {
		print STDERR " ",join(" ",qw/mv --/,$link_to,$target),"\n";
	}
	chdir $kwd;
	return 1;
}
if($OPTS{notdry}) {
	open $FH_LOG,">>","unln.log" or die("Error open file unln.log:$!\n");
}
foreach(@ARGV) {
	next unless(-l $_);
	print STDERR "Processing $_\n";
	movefile($_,$OPTS{dest});
}
close $FH_LOG if($FH_LOG);


__END__

=pod

=head1  NAME

unln - Undo symlink

=head1  SYNOPSIS

unln [options] ...

=head1  OPTIONS

=over 12

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

    2015-01-31 01:09  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
