#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::is_modified;


use strict;
use v5.8.0;
use MyPlace::Usage;
our $VERSION = 'v0.1';

my %OPTS;
my @OPTIONS = qw/help|h|? version|ver edit-me manual|man write|w/;
if(@ARGV)
{
    require Getopt::Long;
    Getopt::Long::GetOptions(\%OPTS,@OPTIONS);
    MyPlace::Usage::Process(\%OPTS,$VERSION);
}
else
{
    MyPlace::Usage::PrintHelp();
    exit 0;
}

sub load_database {
	my %database;
	open FI,'<','.is-modified' or return({});
	while(<FI>) {
		if(m/\s*(.+)?\s*:\s*(\d+)?\s*$/) {
			$database{$1} = $2;	
		}
	}
	close FI;
	return \%database;
}
sub save_database {
	my $database = shift;
	open FO,'>','.is-modified' or die("$!\n");
	foreach(keys %{$database}) {
		print FO "$_:$database->{$_}\n";
	}
	close FO;
}

sub get_mtime {
	my $file = shift;
	return 0 unless($file and -e $file);
	return (stat($file))[9];
}

my $database = load_database();
foreach(@ARGV) {
	next unless($_);
	if(! -e $_) {
		print STDERR "\"$_\" is not exist.\n";
		next;
	}
	elsif($database->{$_}) {
		my $cur = get_mtime($_);
		if($database->{$_} != $cur) {
			print $_,"\n";
			$database->{$_} = $cur;
			next;
		}
	}
	else {
		print $_,"\n";
		$database->{$_} = get_mtime($_);
		next;
	}
	#print STDERR "\"$_\" is not modified\n";
}
save_database($database) if($OPTS{write});

__END__

=pod

=head1  NAME

is-modified - Test MTIME for files.

=head1  SYNOPSIS

is-modified [options] file [file...]

	is-modified path_to_filename
	is-modified path_to_directory

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

    2011-12-26 19:09  afun  <afun@myplace.hell>
        
        * file created.

=head1  AUTHOR

afun <afun@myplace.hell>

=cut

#       vim:filetype=perl

