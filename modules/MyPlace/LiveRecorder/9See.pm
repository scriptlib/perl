#!/usr/bin/perl -w
package MyPlace::LiveRecorder::9See;
use strict;
use warnings;
use parent 'MyPlace::LiveRecorder';

sub def_check1 {
	my $self = shift;
	my $id = shift;
	my $name = shift;
	return {
		match=>qr/"roominfo"/,
		CURL=>[
			'http://www.miaobolive.com/MiaoBo/live/live_room_userinfo.aspx?useridx=' . $id,
		],
		stop=>1,
	};
}

sub def_live {
	my $self = shift;
	my $id = shift;
	my $url = 'http://www.miaobolive.com/MiaoBo/live/live_room_userinfo.aspx?useridx=' . $id;
	if(open FI,'-|','curl','--silent',$url) {
		while(<FI>) {
			if(m/"flv"\s*:\s*"([^"]+\.flv)"/) {
				close FI;
				return {CURL=>['-L','--url',$1]};
			}
		}
		close FI;
	}
	return undef;
}

sub new {
	my $class = shift;
	my $self = $class->SUPER::new('9see');
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
my $PROGRAM = new MyPlace::LiveRecorder::9See;
exit $PROGRAM->execute(@ARGV);
 

