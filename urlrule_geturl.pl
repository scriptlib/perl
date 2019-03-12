#!/usr/bin/env perl 
# $Id$
#===============================================================================
#         NAME: urlrule_geturl
#  DESCRIPTION: 
#       AUTHOR: xiaoranzzz <xiaoranzzz@MYPLACE>
# ORGANIZATION: MyPlace HEL ORG.
#      VERSION: 1.0
#      CREATED: 2019-02-26 01:31
#     REVISION: ---
#===============================================================================
package MyPlace::Script::urlrule_geturl;
use strict;
use MyPlace::URLRule::Utils qw/get_url/;
print get_url(@ARGV);

__END__

=pod

=head1  NAME

urlrule_geturl - PERL script

=head1  SYNOPSIS

urlrule_geturl [options] ...

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

    2019-02-26 01:31  xiaoranzzz  <xiaoranzzz@MYPLACE>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MYPLACE>

=cut

#       vim:filetype=perl
