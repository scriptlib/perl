#!/usr/bin/perl -w
# $Id$
use strict;
use warnings;

use MyPlace::Program::SimpleQuery;

my $Q = new MyPlace::Program::SimpleQuery;
exit $Q->execute(@ARGV);



__END__

=pod

=head1  NAME

urlrule_sites - PERL script

=head1  SYNOPSIS

urlrule_sites [options] ...

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

    2014-11-22 02:51  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
