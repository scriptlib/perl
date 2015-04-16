#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::ntfs_junction;
use strict;
use Cwd qw/getcwd/;
use File::Spec::Functions qw/catdir catfile/;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
	target|t
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

sub usage {
	Pod::Usage::pod2usage(-verbose=>$1);
}

sub get_basename {
	my $_ = shift;
	s/[\/\\]+$//;
	s/.*[\/\\]+//;
	return $_;
}

sub ms_path {
	my $src = shift;
	my $dst = `cygpath -w "$src"`;
	chomp($dst);
	return $dst;
}

sub junction {
	my $target = shift;
	my $junction = shift;
	print STDERR "  Create junction $junction\n   =>$target>\n";
	my @prog = (qw/junction.exe/);
	return (system(@prog,$junction,$target)==0);
}

if($OPTS{'target'}) {
	my $DSTD = $OPTS{'target'};
	if(! -d $DSTD) {
		print STDERR "Directory not exist: $DSTD\n";
		exit 2;
	}
	$DSTD = ms_path($DSTD);
	if(!@ARGV) {
		usage();
		exit 1;
	}
	foreach my $src (@ARGV) {
		my $src = $_;
		my $name = get_basename($src);
		junction($src,$DSTD . "\\" . $name);
	}
}
else {
	my $target = shift;
	my $junction = shift;
	if(!($junction and $target)) {
		usage();
		exit 1;
	}
	if($junction eq '.') {
		$junction = get_basename($target);
	}
	elsif($junction =~ m/\/$/) {
		$junction = catfile($junction,get_basename($target));
	}
	exit junction(ms_path($target),ms_path($junction));
}



__END__

=pod

=head1  NAME

ntfs-junction - PERL script

=head1  SYNOPSIS

ntfs-junction [options] ...

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

    2015-03-19 21:50  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl

