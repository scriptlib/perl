#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::classifiles;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
	dest|d:s
	rule|r:s
	test|t
	verbose|v
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
	my $v = $OPTS{'help'} ? 1 : 2;	Pod::Usage::pod2usage(-exitval=>$v,-verbose=>$v);
    exit $v;
}
my @args = (
	'--by'=>'filename',
	'--action'=>'move',
);
push @args,'--verbose' if($OPTS{'verbose'});
push @args,'--test' if($OPTS{'test'});
push @args,'--dest', $OPTS{'dest'} if($OPTS{dest});
push @args,'--rule',$OPTS{'rule'} if($OPTS{rule});
exec('classify',@ARGV,@args);

__END__

=pod

=head1  NAME

classifiles - classify files

	Classify files by rule.

=head1  SYNOPSIS

classifiles [options] ...

=head1  OPTIONS

=over 12

=item B<--dest>

Specified destination directory

=item B<--rule>

Specified filename of rules

=item B<--test>

Test mode, no moving files around.

=item B<--verbose>

More verbose

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

    ___DATE___  ___AUTHOR___  <___EMAIL___>
        
        * file created.

=head1  AUTHOR

___AUTHOR___ <___EMAIL___>

=cut

#       vim:filetype=perl
