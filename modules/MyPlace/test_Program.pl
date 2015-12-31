#!/usr/bin/perl -w

my $p = MyPlace::Program::Test->new({
			"options1"=>'options1',
			"options2"=>'options2'},
			'z','y','x'
);

$p->execute("--options2","options2_changed","--options3","options3",qw/a b c/,@ARGV);

MyPlace::Program::Test->run(
	"--options2","options2_changed","--options3","options3",qw/a b c/,@ARGV
);

MyPlace::Program::Test->run(@ARGV);

package MyPlace::Program::Test;
use base 'MyPlace::Program';

sub OPTIONS {
	qw/
		options1|o1=s
		options2|o2=s
		options3|o3=s
		options4|o4=s
		options5|o5=s
		help|h
	/;
}

sub MAIN {
	my $self = shift;
	my $options = shift;
	my @args = @_;
	use Data::Dumper;
	print STDERR Data::Dumper->Dump([$options,\@args],[qw/$options $args/]),"\n";
}

__END__

=pod

=head1  NAME

MyPlace::Program::test_Program

=head1  SYNOPSIS

MyPlace::Program::test_Program [options...] URL TITLE


=head1  OPTIONS

=over 12

=item B<--history>

Enable tracking history of URL by URLS.txt

=item B<--overwrite>

Overwrite target if file exists

=item B<--exts>

File formats by orders for downloading, e.g. .mov, .mp4, .flv

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

    2014-11-26 00:18  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl


