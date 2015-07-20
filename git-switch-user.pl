#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::git_switch_user;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
	global
	local
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
my $user = shift;
my $sshdir = "$ENV{HOME}/.ssh/";
my $users = {
	"eotect"=>['Eotect Nahn','eotect#gxxxx.com','eotect'],
	"afun"=>['Afun Nahn','afun#myplace.hell','afun'],
	'nahncm'=>['Coding Machine','nahncm#gxxxx.com','nahncm'],
};
if(not $users->{$user}) {
	print STDERR "User not exists: $user\n";
	exit 1;
}
my $name = $users->{$user}->[0];
my $email = $users->{$user}->[1];
$email =~ s/#/@/g;
$email =~ s/gxxxx\./gmail./g;
my $ssh = $users->{$user}->[2];
my @gitopts;
push @gitopts, ($OPTS{global} ? '--global' : '--local');

print STDERR "Config user name to [$name]\n";
system("git","config",@gitopts,"user.name",$name);
print STDERR "Config uesr email to [$email]\n";
system("git","config",@gitopts,"user.email",$email);
for my $file (qw/id_rsa id_rsa.pub/) {
	print STDERR "Coping [$sshdir/$ssh/$file] ...\n";
	system("cp","-a","$sshdir/$ssh/$file","$sshdir/$file");
}
print STDERR "Switching done."
__END__

=pod

=head1  NAME

git-switch-user - PERL script

=head1  SYNOPSIS

git-switch-user [options] ...

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

    2013-09-01 20:18  xiaoranzzz  <xiaoranzzz@Mainstream>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@Mainstream>

=cut

#       vim:filetype=perl
