package Zim::History;

use strict;

our $VERSION = '0.20';

sub read {
	# FIXME hard-coded property name
	# FIXME more elegant storage model
	my $self = shift;
	return unless $self->{file} and $self->{file}->exists;
	my $fh = $self->{file}->open('r') or return;
	<$fh> =~ /^zim: version $VERSION$/ or return;
	<$fh> =~ /^point: (\d+)$/ or return;
	$self->{point} = $1;
	<$fh> =~ /^hist: (\d+)$/ or return;
	my $h = $1;
	my %seen;
	my $i = 0;
	while (<$fh>) { # read hist
		/^(.+)\/(\d+)$/ or last;
		my $rec = $seen{$1} || {name => $1, state => {cursor => $2}};
		@$rec{'namespace', 'basename'}
			= Zim::Page->split_name($$rec{name});
		push @{$self->{hist}}, $rec;
		$seen{$$rec{name}} = $rec;
		last if ++$i >= $h; # h == scalar @hist
	}
	while (<$fh>) { # read recent
		/^(.*)\/(\d+)$/ or last;
		my $rec = $seen{$1} || {name => $1, state => {cursor => $2}};
		@$rec{'namespace', 'basename'}
			= Zim::Page->split_name($$rec{name});
		push @{$self->{recent}}, $rec;
		$seen{$$rec{name}} = $rec;
	}
	$fh->close;
	$self->{current} = $self->{hist}[ $self->{point} ];
	#use Data::Dumper; warn "Seen: ", Dumper \%seen;
}

=item C<write>

Write the cache file.

=cut

sub write {
	my $self = shift;
	$self->_save_state;
	# FIXME hard-coded property name
	# FIXME more elegant storage model
	return unless $self->{file};
	$$_{state}{cursor} ||= 0 for @{$$self{hist}}, @{$$self{recent}};
	$self->{file}->write(
		"zim: version $VERSION\n",
		"point: $$self{point}\n",
		"hist: ".scalar(@{$$self{hist}})."\n",
		map "$$_{name}\/$$_{state}{cursor}\n",
			@{$$self{hist}}, @{$$self{recent}}
	);
}

1;
