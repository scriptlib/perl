#!/usr/bin/perl -w
package MyPlace::LiveRecorder::LiaoKe;
use strict;
use warnings;
use parent 'MyPlace::LiveRecorder';

sub def_check1 {
	my $self = shift;
	my $id = shift;
	my $name = shift;
	return {
		match=>qr/\s*flv\s*:\s*'[^']+\.flv'/,
		CURL=>[
			'https://www.liaoke.tv/mobile/room/' . $id . '?inviter=10357561',
		],
		stop=>1,
	};
}

sub def_live {
	my $self = shift;
	my $id = shift;
	my $url = 'https://www.liaoke.tv/mobile/room/' . $id . '?inviter=10357561';
	if(open FI,'-|','curl','--silent',$url) {
		while(<FI>) {
			if(m/\s*flv\s*:\s*'([^']+\.flv)'/) {
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
	my $self = $class->SUPER::new('LiaoKe');
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
my $PROGRAM = new MyPlace::LiveRecorder::LiaoKe;
exit $PROGRAM->execute(@ARGV);
 

