#!/usr/bin/perl -w
use strict;
use warnings;
package MyPlace::ICmd;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw(icmd_unknown icmd_read icmd_execute icmd_prompt icmd_data icmd_start icmd_parse icmd_run icmd_message);
    @EXPORT_OK      = qw();
}

sub icmd_run {
	if(!@_) {
		icmd_start($0);
		return;
	}
	my $state = icmd_parse(@_);
	if((!$state) or $state->{start}) {
		icmd_start($0,@_);
		return;
	}
	return $state;
}

sub icmd_execute {
	my($data,$cmd,@args) = @_;
	my @cmds = ($cmd,@args);
	if($data->{data} and (!$data->{inline})) {
		my $t = $data->{pos} || 'end';
		my $lastidx = scalar(@cmds) - 1;
		my $idx = $lastidx + 1;
		if($t eq 'end') {
			push @cmds,'--';
			$idx = $idx+1;
		}
		elsif($t == -1) {
			$idx = $idx;
		}
		else {
			$idx = $t;
		}
		my $i = $lastidx + 1;
		while($i>$idx) {
			$cmds[$i] = $cmds[$i-1];
			$i = $i - 1;
		}
		$cmds[$idx] = $data->{data};
	}
#	print STDERR "SYSTEM: " . join("\n",@cmds),"\n";
	system(@cmds);
#	exec(@cmds);
}

sub icmd_parse {
	my($data,$cmd,@words) = @_;
	if($data =~ m/^<(.*)>$/) {
		$data = $1;
	}
	else {
		return {
			start=>1,
			args =>[@_],
		};
	}
	if(!$cmd) {
		$cmd = $data;
		$data= '';
	}
	my $inline;
	if($data) {
		foreach(@words) {
			if(s/(?:%N|\{\})/$data/g) {
				$inline = 1;
			}
		}
	}
	my $state = {
		inline=>$inline,
		data=>$data,
		pos=>-1,
		cmd=>$cmd,
		args=>@words ? [@words] : undef,
	};
	return $state;
}

sub icmd_unknown {
	print '#ICMD:UNKNOWN ' . join(" ",@_),"\n";
}

sub icmd_message {
	print '#ICMD:ECHO ' . join(" ",@_),"\n";
}
sub icmd_prompt {
	print '#ICMD:PROMPT ' . join(" ",@_) . "\n";
}

sub icmd_data {
	print '#ICMD:DATA ' . join(" ",@_) . "\n";
}

sub icmd_start {
	return MyPlace::ICmd::Control::start(@_);
}
1;

package MyPlace::ICmd::Control;
use strict;
use warnings;
use Term::ANSIColor qw/color/;
use Cwd qw/getcwd/;
use MyPlace::String::Utils qw/strtime/;
my $DATAPREFIX = '';
my $DATA = '';
my $PROCESSER = '';
my $PROCESSER_NAME = '';
my $PROMPT = '';
my $FHLOG;
my @INPUTS;

sub prompt {
	my $cwd = getcwd;
	my $cwdname = $cwd =~ s/.*[\/\\]//r;
	my $prefix = $DATA ? "[$DATA]" : $PROMPT ? "$PROMPT>" : @_ ? join(" ",@_) . "#" : '';
	print "\e]2;" . "$cwdname>$prefix " . "\7";
	print STDERR color('GREEN'),"$cwdname",color('RESET'),'>',color('YELLOW'),$prefix,color('RESET')," ";
}

sub feed {
	push @INPUTS,@_;
}
sub feed_top {
	unshift @INPUTS,@_;
}
sub message {
	print STDERR color('CYAN'),@_,color('RESET');
}

sub work {
	return unless(@INPUTS);
	my $line = shift(@INPUTS);
	if(@INPUTS) {
#		message scalar(@INPUTS), "jobs remain\n";
	}
	process_line($line);
	return &work();
}

sub process_line {
	my $line = shift;
	if($line =~ /\t/) {
		feed_top(split(/\s*\t\s*/,$line));
		return;
	}
	$line =~ s/\e\[[A-Za-z]//g;
	return process($line);
}

my %SHORT_COMMAND = (
	'D'=>'DATA',
	'L'=>'LOAD',
);
my %SYS_COMMAND = (
	'RM'=>['end','rm','-v'],
	'RMDIR'=>['end','rmdir','-v'],
	'MKDIR'=>['end','mkdir','-v'],
	'MV'=>['-1','mv','-v','--','%N']
);

sub internal_process {
#	message "[PRE_PROCESS] " . join(" ",@_),"\n";
	my $UCMD = shift;
	$UCMD = $SHORT_COMMAND{$UCMD} if($SHORT_COMMAND{$UCMD});
	if($UCMD eq 'CD') {
		chdir join(" ",@_);
		return 1;
	}
	elsif($UCMD eq 'PROMPT') {
		$PROMPT = join(" ",@_);
		return 1;
	}
	elsif($UCMD eq 'LOAD') {
		$PROCESSER = join(" ",@_);
		my $cwd = getcwd;
		$PROCESSER_NAME = $PROCESSER;
		$PROCESSER_NAME =~ s/.*[\\\/]//;
		$PROCESSER = $cwd . "/" . $PROCESSER;
		message "Using processer $PROCESSER_NAME\n";
		if(-f $PROCESSER) {
			if($FHLOG) {
				close $FHLOG;
			}
			open $FHLOG,'>>',$PROCESSER . ".log";
		}
		return 1;
	}
	elsif($UCMD eq 'ECHO') {
		print join(" ",@_),"\n";
		return 1;
	}
	elsif($UCMD eq 'DATAPREFIX') {
		$DATAPREFIX = join(" ",@_);
		return 1;
	}
	elsif($UCMD eq 'DATA' or $UCMD eq 'SELECT') {
		$DATA = join(" ",@_);
		$DATA = $DATAPREFIX  . $DATA if($DATAPREFIX);
		return 1;
	}
	elsif($UCMD =~ m/^(?:SYSTEM|SYS|RUN|EXEC|!(.+))$/) {
		my $cmd = $1 ? lc($1) : shift(@_);
		my $state = MyPlace::ICmd::icmd_parse("<$DATA>",$cmd,@_);
		$state->{pos} = 'end';
		MyPlace::ICmd::icmd_execute($state,$state->{cmd},($state->{args} ? @{$state->{args}}: ()));
		return 1;
	}
	elsif($UCMD eq 'UNKNOWN') {
		print STDERR "Unknown command: ",join(" ",@_),"\n";
		return 1;
	}
	else {
		foreach(qw/QUIT EXIT/) {
			if($UCMD eq $_) {
				return 'exit ' . ($_[0] || 0) . ";";
			}
		}
		foreach(keys %SYS_COMMAND) {
			if($UCMD eq $_) {
				my ($pos,@cmds) = @{$SYS_COMMAND{$_}};
				my $state = MyPlace::ICmd::icmd_parse("<$DATA>",@cmds,@_);
				$state->{pos} = $pos || '-1';
				MyPlace::ICmd::icmd_execute($state,$state->{cmd},($state->{args} ? @{$state->{args}}: ()));
				return 1;
			}
		}
	}
	return undef;
}

sub process {
#	message "[PROCESS] " . join(" ",@_),"\n";
	if($FHLOG) {
		print $FHLOG strtime, ": ",join(" ",@_),"\n";
	}
	local $_ = shift;
	my ($cmd,@words) = split(/ /,$_);
	my $UCMD = uc($cmd);
	
	my $CONTROL = internal_process($UCMD,@words);
	if($CONTROL) {
		return eval($CONTROL);
	}
	return &load($_);
}

sub load {
	local $_ = shift;
	if(!open FI,'-|',"\"$PROCESSER\" \"<$DATA>\" $_") {
		message "Error executing \"$PROCESSER\"\n";
		return 1;
	}
	my @TEXT;
	my @LINES;
	foreach my $s(<FI>) {
		if($s =~ m/^#ICMD\s*:\s*UNKNOWN\s*$/) {
			my $cmds = $_;
			if(!$DATA) {
			}
			elsif($cmds =~ m/(?:%N|\{\})/) {
				$cmds =~ s/(?:%N|\{\})/$DATA/g; 
			}
			else {
				$cmds = $cmds ? "$cmds \"$DATA\"" : "\"$DATA\"";
			}
			#message "SYSTEM: $cmds\n";
			system($cmds);
		}
		elsif($s =~ m/^#ICMD\s*:\s*(.+)\s*$/) {
			chomp;
			push @LINES,$1;
		}
		else {
			push @TEXT,$s;
		}
	}
	close FI;
	print STDERR @TEXT if(@TEXT);
	feed_top(@LINES) if(@LINES);
}

sub start {
	$PROCESSER = shift;
	internal_process('LOAD',$PROCESSER);
	&load('START');
	if(@_) {
		my $data = shift;
		$data = "DATA $data";
		&prompt();
		print STDERR "$data\n";
		feed($data);

		my $line = join(" ",@_);
		if($line) {
			&prompt();
			print STDERR $line,"\n";
			feed($line);
		}
#		feed('EXIT');
	}
	my $EXIT = &work();
	&prompt();
	while(<STDIN>) {
		my $LAST;
		chomp;
		if($_) {
			&feed($_);
			$EXIT = &work();
		}
		&prompt();
	}
	&load('END');
}


return 1 if caller;
close $FHLOG if($FHLOG);
exit start(@ARGV);
1;

