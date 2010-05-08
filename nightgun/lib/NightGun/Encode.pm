package NightGun::Encode;
BEGIN {
	require Exporter;
	@ISA = qw/Exporter/;
	@EXPORT = qw/_to_gtk _to_gtk_a _from_gtk _from_gtk_a/;
}
use Encode;

my $utf8 = Encode::find_encoding("UTF-8");
sub _to_gtk {
	return $utf8->decode($_[0]);
}

sub _to_gtk_a {
	return map{$utf8->decode($_)} @_;
}

sub _from_gtk {
	return $utf8->encode($_[0]);
}

sub _from_gtk_a {
	return map{$utf8->encode($_)} @_;
}



1;
