#!/usr/bin/perl -w
# $Id$
use strict;
require v5.10.0;
our $VERSION = 'v0.1';

BEGIN
{
    our $PROGRAM_DIR = $ENV{XR_PERL_SOURCE_DIR};
    unless($PROGRAM_DIR) {
        $PROGRAM_DIR = $0;
        $PROGRAM_DIR =~ s/[^\/\\]+$//;
        $PROGRAM_DIR =~ s/\/+$//;
        $PROGRAM_DIR = "." unless($PROGRAM_DIR);
    }
    unshift @INC, 
        map "$PROGRAM_DIR/$_",qw{modules lib ../modules ..lib};
}

my %OPTS;
my @OPTIONS = qw/help|h|? version|ver edit-me manual|man/;

if(@ARGV)
{
    require Getopt::Long;
    require MyPlace::Usage;
    Getopt::Long::GetOptions(\%OPTS,@OPTIONS);
    MyPlace::Usage::Process(\%OPTS,$VERSION);
}

my($user,$pass) = @ARGV;
if(!$user) {
    print STDERR "Login Id:";
    $user= readline(*STDIN);
    print STDERR "\n";
    die("Invalid Login Id") unless($user);
}
if(!$pass) {
    print STDERR "Password:";
    $pass= readline(*STDIN);
    print STDERR "\n";
    die("Invalid password") unless($pass);
}
use MyPlace::Sina;
my $sina = MyPlace::Sina->new();
print STDERR "[$user] Logining into sina.com.cn ...\n";
my ($ex,$data) = $sina->login($user,$pass,"http://t.sina.com.cn");
if($data =~ m/"result":true/) {
    print STDERR "[OK]\n";
    exit 0;
}
else {
    print STDERR "[Failed]\n";
    exit 1;
}


__END__

=pod

=head1  NAME

sina.login - PERL script

=head1  SYNOPSIS

sina.login [options] ...

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

    2010-11-09 22:39  xiaoranzzz  <xiaoranzzz@myplace.hell>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@myplace.hell>

=cut

#       vim:filetype=perl
