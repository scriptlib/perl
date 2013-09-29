#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::rename_qsed;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
	debug
	style|s:s
/;
use utf8;
use Encode;
binmode STDERR, 'utf8';
binmode STDOUT, 'utf8';
#binmode STDIN,'utf8';
my $utf8 = find_encoding("utf8");
my @OLDARGV = @ARGV;
@ARGV = ();
foreach(@OLDARGV) {
    push @ARGV,$utf8->decode($_);
}

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


sub getnewname {
	system('mv','--',@_);
}
sub readqsed {
	my $file = shift;
	my $qvod;
	if(open my $FI,'<',$file) {
		while(<$FI>) {
		chomp;
		$_ = $utf8->decode($_);
		if(m/qvod:\/*([^\|]+)\|([^\|]+)\|([^\|]+)\|/) {
			$qvod = {
				id=>$1,
				hash=>$2,
				fullname=>$3,
			};
			last;
		}
		}
		close $FI;
	}
	else {
	}
	return $qvod;
}
sub dirname {
	my $filename = shift;
	my $pos=-1;
	$pos = rindex($filename,'/');
	if($pos<0) {
		$pos = rindex($filename,'\\');
	}
	if($pos>=0) {
		return substr($filename,0,$pos+1);
	}
	else {
		return "";
	}
}
sub process {
	my $count=scalar(@_);
	my $cur=0;
	foreach my $old (@_) {
		$cur++;
		my $qvod = readqsed($old);
		print STDERR "$old\n"if($OPTS{debug});
		if($qvod) {
			my $name;
			if($OPTS{style} eq 'hash') {
				$name = $qvod->{hash};
			}
			elsif($OPTS{style} eq 'fullname') {
				$name = $qvod->{fullname};
			}
			else {
				$name = $qvod->{fullname};
				$name =~ s/^([^\s\[]*[\[【〖［｛『〔〈《「][^\[\]\(\)]+[〕〉》」』〗】｝\]]|www\.([^\.]+)+\.(com|us))[_ ]*//i;
			}
			if($name) {
				my $new = dirname($old);
				$new = $new . $name . '.qsed';
				print STDERR "[$cur/$count] $old\n=>$new\n";
				getnewname($old,$new);
			}
		}
	}
}

$OPTS{style} = 'name' unless($OPTS{style});
my @lines= @ARGV;
if(!@lines) {
	while(<STDIN>) {
		chomp;
		$_ = $utf8->decode($_);
		next unless($_);
		push @lines,$_;
	}
}
process(@lines);

__END__

=pod

=head1  NAME

rename_qsed - rename .qsed files by content

=head1  SYNOPSIS

rename_qsed [options] ...

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

    2013-09-26 01:41  xiaoranzzz  <xiaoranzzz@Mainstream>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@Mainstream>

=cut

#       vim:filetype=perl
