#!/usr/bin/perl -w
# $Id$
package MyPlace::Program::Google;
use strict;
use base 'MyPlace::Program';
use MyPlace::Google;

sub VERSION {'v0.1'}
sub OPTIONS { qw/
	help|h|? 
	manual|man
	web|w
	images|i
	link|l
	dump|d
/;}


sub MAIN {
	my $self = shift;
	my $opts = shift;
	my @argv = @_;
	my $google = new MyPlace::Google;
	if($opts->{images}) {
		unshift @argv,'images';
	}
	elsif($opts->{web}) {
		unshift @argv,'web';
	}
	push @argv,'page',$opts->{page} if($opts->{page});
	my ($status,$r,$res) = $google->search(@argv);

	if($opts->{dump}) {
		print $res,"\n";
	}

	if(!$status) {
		print STDERR $r,"\n";
		return 1;
	}
		
	if($opts->{link}) {
		foreach my $item (@$r) {
			print $item->{source},"\n";
		}
	}
	else {
		foreach my $item (@$r) {
			print $item->{source};
			print "\t",$item->{text} if($item->{text});
			print "\t",$item->{link} if($item->{link});
			print "\n";
		}
	}
	return 0;
}


return 1 if caller;
my $PROGRAM = new MyPlace::Program::Google;
exit $PROGRAM->execute(@ARGV);

1;


__END__

=pod

=head1  NAME

google - PERL script

=head1  SYNOPSIS

google [options] ...

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

    2015-01-28 16:49  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
