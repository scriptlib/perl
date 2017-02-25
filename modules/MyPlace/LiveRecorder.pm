#!/usr/bin/perl -w
package MyPlace::LiveRecorder;
use strict;
use warnings;
use parent 'MyPlace::Program';
use MyPlace::String::Utils qw/strtime/;
sub OPTIONS {qw/
	help|h|? 
	manual|man
	wait|w=i
	seconds|s=i
	runonce
	no-preview|np
	no-ask|na
	preview
	restart
	no-check|nc
	full|repeat
/;}

sub def_check1 {
	die("def_check1 not implemented\n",@_);
}

sub def_check2 {
	die("def_check2 not implemented\n",@_);
}

sub def_live {
	die("def_live not implemented\n",@_);
}

sub new {
	my $class = shift;
	my $self = $class->SUPER::new();
	$self->{hostname} = shift;
	$self->{options} = @_ if(@_);
	return $self;
}

sub check {
	my $self = shift;
	my $result = undef;
	my $check_next = undef;
	if($self->can('def_check1')) {
		($result,$check_next) = $self->check_data(@_);
	}
	return $result if($result);
	return undef unless($check_next);
	if($self->can('def_check2')) {
		return $self->check_info(@_);
	}
	return $result;
}

sub check_data {
	my $self = shift;
	my $r = $self->def_check1(@_);
	return undef,undef unless($r->{match});
	return undef,undef unless($r->{CURL});
	my $get_nothing = 1;
	my @CURL_OBJECT = @{$r->{CURL}};
	print STDERR "[Checking] CURL " . join(" ",@CURL_OBJECT);
	if(open FI,'-|','curl','--silent',@CURL_OBJECT) {
		foreach(<FI>) {
			chomp;
			next unless($_);
			next if(m/^\s+$/o);
			$get_nothing = undef;
			if(m/$r->{match}/) {
				close FI;
				print STDERR "\n\t[OK] ($r->{match})\n";
				return 1,0;
			}
		}
		close FI;
	}
	if($get_nothing) {
		print STDERR "\n\t[NO] (Get NOTHING)\n";
		return undef,1 unless($r->{stop});
	}
	else {
		print STDERR "\n\t[NO]\n";
		return undef,undef;
	}
}

sub check_info {
	my $self = shift;
	my $r = $self->def_check2(@_);
	return undef unless($r->{CURL});
	my @CURL_OBJECT = @{$r->{CURL}};
	print STDERR "[Checking] CURL " . join(" ",@CURL_OBJECT); 
	if(open FI,'-|','curl','--silent',@CURL_OBJECT) {
		foreach(<FI>) {
			chomp;
			next unless($_);
			next if(m/^\s+$/o);
			if(index($_,'404 Not Found')) {
				print STDERR "\n\t[NO] (404 Not Found)\n";
				close FI;
				return undef;
			}
			elsif(!$r->{match}) {
				next;
			}
			elsif(m/$r->{match}/) {
				print STDERR "\n\t[OK] ($r->{match})\n";
				close FI;
				return 1;
			}
		}
		close FI;
	}
	print STDERR "\n\t[NO]\n";
	return undef;
}

sub start {
	my $self = shift;
	my $options = shift;
	my %OPTS = $self->{opitons} ? %{$self->{options}} : ();
	%OPTS = (%OPTS, ($options ? %$options : ()));
	my $wait = $OPTS{wait} || 10;
	my $seconds = $OPTS{seconds} || 600;
	my $id = shift;
	my $name = shift;
	my $start = shift(@_) || strtime(time,4,'','','');
	my $title = $id . ($name ? "_$name" : "");
	my $restart = !$OPTS{'no-ask'};
	my $preview = !$OPTS{'no-preview'};
	my $last_answer = undef;
	if($OPTS{runonce}) {
		if(!$OPTS{'no-check'}) {
			exit 1 unless($self->check($id,$name));
		}
		$restart = $OPTS{'restart'} ? 1 : undef;
		$preview = $OPTS{'preview'} ? 1 : undef;
	}
	if($OPTS{full}) {
		$preview = undef;
		$restart = undef;
		$OPTS{'no-ask'} = 1;
		delete $OPTS{'no-check'};
	}

	while($start) {
	RECORDING:
		if($restart) {
			$preview = undef;
			my $answer;
			if($OPTS{'no-ask'}) {
				$answer = $last_answer || 'y';
			}
			else {
				printf STDERR "%10s : %s\n","Y","Recording without preview";
				printf STDERR "%10s : %s\n","R","Recording with preview";
				printf STDERR "%10s : %s\n","[ENTER]","Repeat last action";
				printf STDERR "%10s : %s\n","...","Exit";
				print STDERR "Start recording for $name $id ? [YOUR ANSWER:] ";
				$answer = <STDIN>;
			}
			if($answer =~ m/^[\s\r\n]+$/) {
				$answer = $last_answer;
				if(not defined $answer) {
					$answer = 'q';
				}
			}
			elsif($answer =~ m/^([YyRr])(\d+)$/) {
				$answer = lc($1);
				$seconds = 60 * $2;
			}
			else {
				$answer = lc(substr($answer,0,1));
			}
			if($answer eq 'y') {
				$start = strtime(time(),4,"","","");
				$preview = undef;
				$last_answer = $answer;
			}
			elsif($answer eq "r") {
				$start = strtime(time(),4,"","","");
				$preview = 1;
				$last_answer = $answer;
			}
			else {
				last;
			}
			if(!$OPTS{'no-check'}) {
				if(!$self->check($id,$name)) {
					last if($OPTS{full});
					next;
				};
			}
		}
		$restart = 1;
		my $r = $self->def_live($id,$name);
		if(!$r->{CURL}) {
			print STDERR "No definition for live $id,$name\n";
			last;
		}
		if(!@{$r->{CURL}}) {
			print STDERR "Empty definition for live $id,$name\n";
			last;
		}
		print STDERR join(" ",@{$r->{CURL}}),"\n";
		my $output = ($self->{hostname} ? "$self->{hostname}_" : ""). $title . "_" . $start . ".flv";
		system("touch","..","../..","../../..","../../../../");
		if($preview) {
			print STDERR "Preview will start in $wait seconds ...\n";
			system("exec_delay $wait kmplayer.bat \"$output\" 2>&1 1>/dev/null &");
		}
		print "\033]2;$name $id [" . ($OPTS{full} ? "FULL " : "") . "RECORDING]\007";
		printf STDERR "%10s %10s %4s\n",$name,$id,"[" . ($seconds / 60) . " Minutes]";
		print STDERR "\tBEGIN: " . localtime() . "\n";
		print STDERR "\t$output\n";
		print STDERR "-"x80,"\n";
		if($r->{SYSTEM}) {
			system(@{$r->{CURL}},"-m",$seconds,"-o",$output);
		}
		else {
			system("curl","-m",$seconds,"-o",$output,@{$r->{CURL}});
		}
		print STDERR "\n","-"x80,"\n";
		print STDERR "\tEND: " . localtime() . "\n";
		print STDERR "$name\t$id\n";
		print "\033]2;<END>$name $id\007";
		next if($OPTS{full});
		last if($OPTS{runonce});
	}
	return 1;
}

1;
