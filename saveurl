#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::saveurl2;
use strict;
use MyPlace::Program::Saveurl;
my $app = new MyPlace::Program::Saveurl;
my @tasks;
#binmode STDOUT,":utf8";
#binmode STDERR,":utf8";
#binmode STDIN,":utf8";
while(<>) {
	chomp;
#	print STDERR ">$_\n";
	push @tasks,$_ if($_);
}
$app->addTask(@tasks);
exit $app->execute(@ARGV);

__END__

=pod

=head1  NAME

saveurl2 - PERL script

=head1  SYNOPSIS

saveurl2 [options] ...

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

    2013-10-31 22:47  xiaoranzzz  <xiaoranzzz@Mainstream>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@Mainstream>

=cut

#       vim:filetype=perl
