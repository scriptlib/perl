#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::git_change_author;
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
else {
	$OPTS{'help'} = 1;
}
if($OPTS{'help'} or $OPTS{'manual'}) {
	require Pod::Usage;
	my $v = $OPTS{'help'} ? 1 : 2;
	Pod::Usage::pod2usage(-exitval=>$v,-verbose=>$v);
    exit $v;
}

my @names;

sub template_replace {
	my ($from,$to) = @_;
	return <<"TEMPLATE";
if [ "\$GIT_COMMITTER_EMAIL" = "$from->{email}" ]
then
    cn="$to->{name}"
    cm="$to->{email}"
fi
if [ "\$GIT_AUTHOR_EMAIL" = "$from->{email}" ]
then
    an="$to->{name}"
    am="$to->{email}"
fi
TEMPLATE
}

while(@ARGV) {
	my $from = shift @ARGV;
	my $to = shift @ARGV;
	next unless($from);
	next unless($to);
	if($from =~ m/([^,]+),([^,]+)$/) {
		$from = {name=>$1,email=>$2};
	}
	else {
		$from = {name=>$from,email=>"$from\@gmail.com"};
	}
	if($to =~ m/([^,]+),([^,]+)$/) {
		$to = {name=>$1,email=>$2};
	}
	else {
		$to = {name=>$to,email=>"$to\@gmail.com"};
	}
	push @names,[$from,$to];
	last;
}
use Data::Dumper;print Data::Dumper->Dump([\@names],['*names']),"\n";

my @envfilter;
push @envfilter,<<'CODE'

an="$GIT_AUTHOR_NAME"
am="$GIT_AUTHOR_EMAIL"
cn="$GIT_COMMITTER_NAME"
cm="$GIT_COMMITTER_EMAIL"
CODE
;

foreach(@names) {
	push @envfilter,template_replace($_->[0],$_->[1]);
}

push @envfilter,<<'CODE'

export GIT_AUTHOR_NAME="$an"
export GIT_AUTHOR_EMAIL="$am"
export GIT_COMMITTER_NAME="$cn"
export GIT_COMMITTER_EMAIL="$cm"
CODE
;

exec(qw/git filter-branch --env-filter/,join("\n",@envfilter),@ARGV);


__END__

=pod

=head1  NAME

git-change-author - PERL script

=head1  SYNOPSIS

git-change-author [options] ...

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

    2011-12-31 16:02  xiaoranzzz  <xiaoranzzz@myplace.hell>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@myplace.hell>

=cut

#       vim:filetype=perl
