#!/usr/bin/perl -w
package MyPlace::LiveRecorder::PandaTV;
use strict;
use warnings;
use parent 'MyPlace::LiveRecorder';

sub get_room {
	my $self = shift;
	my $id = shift;
	my %r;
	my $url = 'http://www.panda.tv/api_room_v2?roomid=' . $id;
	print STDERR "Checking " . $url . " ..."; 
	if(open FI,'-|','curl','--silent',$url) {
		foreach(<FI>) {
			if(m/"status"\s*:\s*"2"\s*,\s*"display_type"\s*:/) {
				$r{status} = 1;	
				print STDERR "\t[OK]\n";
			}
			if(m/"room_key"\s*:\s*"([^"]+)"/) {
				$r{key} = $1;
			}
		}
		close FI;
	}
	print STDERR "\t[NO]\n" unless($r{status});
	return \%r;
}

sub check {
	my $self = shift;
	my $id = shift;
	my $name = shift;
	my $room = $self->get_room($id);
	return undef unless($room->{status});
	$self->{just_checked} = 1;
	$self->{live_key} = $room->{key};
	return 1;
}

sub def_live {
	my $self = shift;
	my $id = shift;
	unless($self->{live_key} or $self->{just_checked}) {
		return {} unless($self->{check_show});
	}
	$self->{just_checked} = undef;
	return {
		CURL=>[
			'--url',
			'http://223.111.17.74/pl3.live.panda.tv/live_panda/' .
				$self->{live_key} . '.flv?wshc_tag=0&wsts_tag=57ded6b4&wsid_tag=df4a3553&wsiphost=ipdbm',
			'--referer',
			'http://www.panda.tv/' . $id,
		],
	};
}

sub new {
	my $class = shift;
	my $self = $class->SUPER::new('pandatv');
	if(@_) {
		$self->set(@_);
	}
	return $self;
}

sub MAIN {
	my $self = shift;
	my $OPTS = shift;
	#use MyPlace::Debug::Dump;die(debug_dump($OPTS),"\n");
	return $self->start($OPTS,@_);
}

return 1 if caller;
my $PROGRAM = new MyPlace::LiveRecorder::PandaTV;
exit $PROGRAM->execute(@ARGV);
 

