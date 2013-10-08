#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::saveqvod;
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
sub normalize {
	my $_ = $_[0];
	s/[\/:\\]/ /g;
	return $_;
}
sub process_http {
	my ($link,$filename) = @_;
	$filename = normalize($filename);
	system('download','-u',$link,'-s',$filename);
	
}
sub process_file {
	my ($link,$filename) = @_;
	$filename = normalize($filename);
	print STDERR "Saving file $filename...\n";
	system('mv','-v','--',$link,$filename);
}
sub process_qvod {
	my ($link,$filename) = @_;
	$filename = normalize($filename);
	if($link && $filename) {
		print STDERR "Saving $filename.qsed ...\n";
		open FO,'>',$filename . '.qsed';
		print FO 
<<"EOF";
	<qsed version="3.5.0.61">
		<entry>
			<ref href="$link"/>
		</entry>
	</qsed>
EOF
		close FO;
	}
}
while(<STDIN>) {
	chomp;
	if(m/^(qvod:\/\/.+)\t(.+)$/) {
		process_qvod($1,$2);
	}
	elsif(m/^qvod:\/\/.+\|([^\|]+)\|$/) {
		process_qvod($_,$1);
	}
	elsif(m/^(http:\/\/.+)\t(.+)$/) {
		process_http($1,$2);
	}
	elsif(m/^file:\/\/(.+)\t(.+)$/) {
		process_file($1,$2);
	}
	elsif(m/^file:\/\/(.+)$/) {
		process_file($1,"./");
	}
	else {
		print STDERR "Ignore $_\n";
	}
}


__END__

=pod

=head1  NAME

saveqvod - PERL script

=head1  SYNOPSIS

saveqvod [options] ...

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

    2013-10-07 08:24  xiaoranzzz  <xiaoranzzz@Mainstream>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@Mainstream>

=cut

#       vim:filetype=perl
