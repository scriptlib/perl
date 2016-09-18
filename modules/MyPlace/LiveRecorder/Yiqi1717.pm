#!/usr/bin/perl -w
package MyPlace::LiveRecorder::Yiqi1717;
use strict;
use warnings;
use parent 'MyPlace::LiveRecorder';

sub def_check1 {
	my $self = shift;
	my $id = shift;
	my $name = shift;
	return {
		match=>qr/is_live\s+:\s+true/,
		CURL=>[
			'http://www.yiqi1717.com/share/live?uid=' . $id,
		],
		stop=>0,
	};
}
sub def_check2 {
	my $self = shift;
	my $id = shift;
	my $name = shift;
	return {
		match=>undef,
		CURL=>[
			'-I',
			'http://yiqihdl.8686c.com/pajia/' . $id . '.flv'
		],
		stop=>1,
	};
}

sub def_live {
	my $self = shift;
	my $id = shift;
	return {
		CURL=>[
			'--url',
			'http://yiqihdl.8686c.com/pajia/' . $id . '.flv',
		],
	};
}

sub new {
	my $class = shift;
	my $self = $class->SUPER::new('yiqi1717');
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
my $PROGRAM = new MyPlace::LiveRecorder::Yiqi1717;
exit $PROGRAM->execute(@ARGV);
 

