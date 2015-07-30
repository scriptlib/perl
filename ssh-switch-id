#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::ssh_switch_id;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
/;
my %OPTS;
if(@ARGV)
{
    require Getopt::Long;
    Getopt::Long::GetOptions(\%OPTS,@OPTIONS);
}
if($OPTS{'help'} or $OPTS{'manual'}) {
	require Pod::Usage;
	my $v = $OPTS{'help'} ? 1 : 2;
	Pod::Usage::pod2usage(-exitval=>$v,-verbose=>$v);
    exit $v;
}
use File::Spec;
use File::Glob qw/bsd_glob/;
my $id = shift;
my $srcd = File::Spec->catdir($ENV{HOME},".ssh");
my $dstd = $srcd;

my @names;
opendir my $DH,$srcd or die("Error opening $srcd: $!\n");
while(readdir($DH)) {
	next if(m/^\.+$/);
	next if(-f $_);
	push @names,$_;
}
closedir $DH;


if(!$id) {
	print STDERR "Current ID id:\n\t";
	system("cat","--",File::Spec->catfile($dstd,".current_id"));
	print STDERR "____\n";
	print STDERR "Available ID are:\n";
	print STDERR "\t",join("\n\t",@names),"\n";
	print STDERR "____\n";
	exit 0;
}

my $TARGET;

foreach(@names){
	if($_ eq $id) {
		$TARGET = $_;
		last;
	}
}
if(!$TARGET) {
	foreach(@names) {
		if(m/$id/i) {
			$TARGET = $_;
			last;
		}
	}
}
if(!$TARGET) {
	die("ERROR ID NOT EXIST: $id\n");
}

foreach(qw/id_rsa id_rsa.pub/) {
	my $source = File::Spec->catfile($srcd,$TARGET,$_);
	my $dest = File::Spec->catfile($dstd,$_);
	open FI,"<:raw",$source or die("Error opening $source:$!\n");
	open FO,">:raw",$dest or die("Error opening $dest:$!\n");
	print FO <FI>;
	close FI;
	close FO;
	print STDERR "Copied $source.\n";
}
open FO,">",File::Spec->catfile($dstd,".current_id");
print FO $TARGET,"\n";
close FO;

__END__

=pod

=head1  NAME

ssh-switch-id - PERL script

=head1  SYNOPSIS

ssh-switch-id  ID

	ssh-switch-id eotect@myplace
	ssh-switch-id eotect

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

    2014-07-20 23:10  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
