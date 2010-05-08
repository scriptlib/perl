package Zim::GUI;
sub open_url {
	my ($self, $url, $app) = @_;
	# type is a private argument used for error handling for interwiki
        $url =~ s/^$app:\/\///;
	Zim::Utils->run($app,$url);
}
1;
