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
sub run{
	system(@_) == 0;
}
my $action = $OPTS{action} || 'Update';
my $cmd = 'add';
$cmd = 'rm' if(($action eq 'Delete') || ($action eq 'delete'));
my $action_done = $action;
$action_done =~ s/e?$/ed/;
my $message = $OPTS{message} ? $OPTS{message} . "\n\n" : '';
foreach(@ARGV) {
	run('git',$cmd,$_);
	$message .= "\t$action file: $_\n"
}
run(qw/git commit -m/,$message);

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
