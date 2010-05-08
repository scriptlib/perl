package Zim::Store;

sub clean_name {
	my (undef, $name, $rel) = @_;
	#print STDERR "resolved $name to ";
	$name =~ s/^:*/:/ unless $rel;		# absolute name
	$name =~ s/:+$//;			# not a namespace
	$name =~ s/::+/:/g;			# replace multiple ":"
#	$name =~ s/[^:\w\.\-\(\)\%]/_/g;	# replace forbidden chars
#	$name =~ s/(:+)[\_\.\-\(\)]+/$1/g;	# remove non-letter at begin
#	$name =~ s/_+(:|$)/$1/g;		# remove trailing underscore
	#print STDERR "$name\n";
	$name = undef if $name eq ':';
	return $name;
}
1;
