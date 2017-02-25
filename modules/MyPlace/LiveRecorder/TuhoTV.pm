#!/usr/bin/perl -w
package MyPlace::LiveRecorder::TuhoTV;
use strict;
use warnings;
use parent 'MyPlace::LiveRecorder';

sub def_check1 {
	my $self = shift;
	my $id = shift;
	my $name = shift;
	return {
		match=>qr/isPlaying\s*:\s*true\s*,/,
		CURL=>[
			'http://www.tuho.tv/' . $id,
		],
		stop=>1,
	};
}

sub def_live {
	my $self = shift;
	my $id = shift;
	my $url = 'http://www.tuho.tv/' . $id;
	if(open FI,'-|','curl','--silent',$url) {
		while(<FI>) {
			if(m/\s*rid\s*:\s*["']?(\d+)/) {
				close FI;
				my $rtmp =  "rtmp://rtmppull.efeizao.com/live/room_$1/chat";
				return {SYSTEM=>1,CURL=>['record_rtmp',$rtmp]};
			}
		}
		close FI;
	}
	return undef;
}

sub new {
	my $class = shift;
	my $self = $class->SUPER::new('TuhoTV');
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
my $PROGRAM = new MyPlace::LiveRecorder::TuhoTV;
exit $PROGRAM->execute(@ARGV);
 

