#!/usr/bin/perl -w
use strict;
use warnings;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw(&qcmd_run);
    @EXPORT_OK      = qw();
}
use Term::ANSIColor qw/color/;

my $CMD = 'echo';
my $NAME = '';
my @ARGS = ();
my $PROMPT = '';

sub qcmd_set {
	if(@_) {
		($CMD,@ARGS) = @_;
	}
}

sub qcmd_name {
	$NAME = shift;
}

sub color1 {
	return color('GREEN') . join(" ",@_) . color('RESET');
}
sub color2 {
	return color('CYAN') . join(" ",@_) . color('RESET');
}

sub _build_prompt {
	my $c1 = shift;
	my $c2 = shift;
	my $p1 = $c1 ? color($c1) . $NAME . color('RESET') : $NAME if($NAME);
	my $p2 = $c1 ? color($c1) . $CMD . color('RESET') : $CMD if($CMD);
	my $p3 = $c1 ? color($c2) . $PROMPT . color('RESET') : $PROMPT if($PROMPT);

	my $p = $NAME ? $p1 . ">" : $CMD ? $p2 . ">" : ">";
	$p .= $PROMPT ? $p3 . ">" : "";
	$p .= " ";
	$p .= join(" ",@_) if(@_);
	return $p;
}

sub qcmd_prompt {
	print "\e]2;" . _build_prompt(undef,undef,@_) . "\7";;
	print STDERR _build_prompt('GREEN','CYAN',@_);
}

my %vtable = (
	'CMD'=>'COMMAND',
	'Q'=>'QUIT',
	'EXIT'=>'QUIT',
	'COMMAND'=>'COMMAND',
	'QUIT'=>'QUIT',
	'PROMPT'=>'PROMPT',
	'SYS'=>'SYSTEM',
	'SYSTEM'=>'SYSTEM',
);

my %ctable = (
);

sub qcmd_add {
	return unless(@_);
	my $name = shift;
	my $uname = uc($name);
	$vtable{$uname} = $uname;
	$ctable{$uname} = @_ ? [@_] : [$name];
}

sub qcmd_execute {
	my $cmd = shift;
	$cmd = 'echo' unless($cmd);
#	if($ctable{uc($cmd)}) {
#		return system(@{$ctable{uc($cmd)}},@_) == 0;
#	}
	return system($cmd,@_) == 0;
}

sub qcmd_run {
	&qcmd_prompt;		
	my $ok = 1;
	while(<STDIN>) {
		chomp;
		if($_) {
			my($verb,@words) = split(/\s+/,$_);
			my $VERB = $vtable{uc($verb)};
			if(!$VERB) {
				@words = split(/\s+>\s+/,$_);
				$ok = qcmd_execute($CMD,@ARGS,@words);
			}
			elsif($VERB eq 'QUIT') {
				$ok = 1;
				last;
			}
			elsif($VERB eq 'COMMAND') {
				$ok = 1;
				qcmd_set(@words);
			}
			elsif($VERB eq 'SYSTEM') {
				$ok = qcmd_execute(@words);
			}
			elsif($ctable{$VERB}) {
				$ok = qcmd_execute(@{$ctable{$VERB}},@words);
			}
			else {
				@words = split(/\s+>\s+/,$_);
				$ok = qcmd_execute($CMD,@ARGS,@words);
			}
		}
		&qcmd_prompt;
	}
	return $ok ? 0 : 1;
}

1;
