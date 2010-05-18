package NightGun::Gui::View;
use strict;
use fields qw/name id listener parent widget viewer/;

sub new {
	my $class = shift;
	my $self = fields::new($class) unless(ref $class);
	$self->{name}=$class unless(ref $class);
	return $self;
}

#sub zoom_out {
#}
#
#sub zoom_in {
#}
#
#sub go_back {
#}
#sub go_forward {
#}
#
#sub get_state {
#}
#sub set_state {
#}
#
#sub encoding_changed {
#}
#
#sub set_uri {
#}
#sub set_stream {
#}
#
#sub set_content {
#}
#
#sub get_content {
#}
#
1;
