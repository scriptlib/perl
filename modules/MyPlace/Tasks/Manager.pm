#!/usr/bin/perl -w
package MyPlace::Tasks::Manager;
use MyPlace::Program qw/EXIT_CODE/;
use strict;
use warnings;

use File::Spec::Functions qw/catfile catdir splitdir/;

our $CONFIG_DIR = '.mtm';
our $DB_DONE = 'done.txt';
our $DB_QUEUE = 'queue.txt';
our $DB_FAILED = 'failed.txt';
our $DB_IGNORE = 'ignore.txt';


sub new {
	my $class = shift;
	my $self = bless {
			options=>{},
		},$class;
	delete $self->{exited};
	$self->set(@_);
	return $self;
}

sub set {
	my $self = shift;
	$self->{options} = {%{$self->{options}},@_};
	return $self->{options};
}

sub get {
	my $self = shift;
	if(@_) {
		my %r;
		foreach(@_) {
			$r{$_} = $self->{options}->{$_};
		}
		return %r;
	}
	else {
		return (%{$self->{options}});
	}
}

sub touch_path {
	my $dir = shift;
	my $level = shift;
	$level = 5 unless(defined $level);
	$level = 0 if($level < 0);
	my @dirs = splitdir($dir);
	my @ts;
	while($level > 0) {
		push @ts,$dir;
		pop @dirs;
		last unless(@dirs);
		$dir = catdir(@dirs);
		$level = $level - 1;
	}
	print STDERR "Touching path:\n\t" . join("\n\t",@ts) . "\n";
	system("touch","--",@ts) == 0;
}

use Cwd qw/getcwd/;

my $MSG_PROMPT = 'MTM';

sub p_prompt {
	print STDERR "\n",$MSG_PROMPT,">\n";
	&p_msg(@_) if(@_);
}

sub set_prompt {
	my $self = shift;
	$MSG_PROMPT = shift;
}

sub get_prompt {
	my $self = shift;
	return $MSG_PROMPT;
}

sub p_msg {
	print STDERR "  ",@_;
}

sub p_err {
	goto &p_msg;
}

sub p_warn {
	goto &p_msg;

}
sub _read_lines {
	my $self = shift;
	my $filename = shift;
	my $dir = shift;
	my $source = $dir ? catfile($dir,$filename) : $filename;
	my @input;
	my $counter = 0;
	if(! -f $source) {
		#&p_warn("Input file $source not exists [IGNORED]\n");
	}
	elsif(open(my $FI,'<',$source)) {
		$counter = 0;
		foreach(<$FI>) {
			chomp;
			next unless($_);
			if(m/^#([^:]+?)\s*:\s*(.*)$/) {
				p_warn "source $1 => $2\n";
				$self->{source}->{$1} = ($2 || "");
				next;
			}
			$counter++;
			push @input,$_;
		}
		close $FI;
		&p_msg("Read $counter lines for $source\n");
	}
	else {
		&p_warn("Error opening $source [IGNORED]\n");
	}
	return @input;
}

sub _write_lines {
	my $data = shift;
	my $filename = shift;
	my $dir = shift;
	my $source = $dir ? catfile($dir,$filename) : $filename;
	my $mode = shift(@_) || '>';
	my @input = (($data && @{$data}) ? @{$data} : ());
	my $counter = 0;
	if(open(my $FO,$mode,$source)) {
		$counter = 0;
		foreach(@input) {
			$counter++;
			print $FO "$_\n";
		}
		close $FO;
		&p_msg("Write $counter lines to $source\n");
		return 1;
	}
	else {
		&p_err("Error opening $source [IGNORED]\n");
		return undef;
	}
}


sub get_key {
	my $str = shift;
	#print STDERR "$str => ";
	return unless($str);
	if(index($str,'sinaimg.cn')) {
		$str =~ s/:\/\/ww\d+\./:\/\/ww1./;
		#print STDERR $str,"\n";
	}
	elsif($str =~ m/p\d*\.pstatp.com\/(large\/[^\s"&\/]+)\.jpe?g/) {
		$str = "douyin:$1.jpg";
	}
	elsif($str =~ m/p\d*-dy\.bytecdn\.cn\/(large\/[^"&\s\/]+)\.jpe?g/) {
		$str = "douyin:$1.jpg";
	}
	elsif($str =~ m/aweme\.snssdk\.com\/aweme\/.*\?video_id=([^\s&"]+)/) {
		$str = "douyin:$1.mp4";
	}
	$str =~ s/(?:\t| {3,}).+$//;
	#print "$str\n";
	return $str;
}

sub unique {
	my $source = shift;

	return unless($source and @{$source});
	return @{$source} unless(@_);
	
	my $ignore = shift(@_) || [];

	my @r;
	
	my %holder;
	foreach(@_) {
		$holder{get_key($_)} = 1;
	}
	my $count = 0;
	foreach(@{$source}) {
		my $k = get_key($_);
		if(defined($holder{$k})) {
			push @$ignore,$_;
			$count++;
#			print STDERR "\r\b\b\b\b\b\b\b$count Ignored";
#			print STDERR $k,"\n";
#			print STDERR "Ignored $_\n";
		}
		else {
			$holder{$k} = 1;
			push @r,$_;
		}
	}
	print STDERR "\t$count urls duplicated\n";
	return @r;
}

sub run {
	my $self = shift;
	my $CWD_KEPT = getcwd;
	my @x = $self->_run(@_);
	chdir $CWD_KEPT;
	return @x;
}

sub _run {
	my $self = shift;
	delete $self->{exited};
	my %opt = %{$self->{options}};
	my @arguments = @_;
	
	if(@arguments and $arguments[0] and -d $arguments[0] and !$opt{directory}) {
		$opt{directory} = shift(@arguments);
	}

	if(!(@arguments or $opt{input})) {
		$opt{input} = 'urls.lst';
	}
	
	if($opt{'no-mtm'}) {
		foreach(qw/no-failed no-ignored no-done/) {
			$opt{$_} = 1;
		}
	}


	my $worker = $opt{worker};

	my $COUNTER = 0;
	my $COUNTALL = 0;

	$MSG_PROMPT = defined($opt{title}) ? $opt{title} :
			defined($opt{directory}) ? $opt{directory} : 
			'MyPlace Tasks Manager';
	$MSG_PROMPT .= "/";

	&p_prompt();

	if(!$worker) {
		p_err "Error not worker defined\n";
		return undef,4,"no worker defined"; 
	}
	
	my $CWD_KEPT;
	if($opt{directory}) {
		#$CWD_KEPT = getcwd;
		#	print STDERR "CWD:$CWD_KEPT\n";
		p_msg "Entering $opt{directory}\n" unless($opt{simple} or $opt{quiet});
		#print STDERR "chdir $opt{directory}\n";
		if(!chdir $opt{directory}) {
			#p_err "PWD:\t$CWD_KEPT\n";
			p_err "Error:$! [$opt{directory}]\n";
			return undef,4,"$! [$opt{directory}]";
		}
	}

	if($opt{recursive}) {
		my $kd = $opt{directory};
		my $kt = $opt{title};
		my $km = $MSG_PROMPT;
		#my $KWD = getcwd;
		my @subdir;
		foreach(glob('*')) {
			next if(m/^\.[^\/]*/);
			push @subdir,$_ if(-d $_);
		}
		foreach(@subdir) {
			#chdir $KWD;
			$self->{options}->{directory} = $_;
			$self->{options}->{title} = $MSG_PROMPT . $_;
			$MSG_PROMPT .=  $_;
			my ($count,$val,$msg) = $self->run();
			$COUNTER += $count if($count);
			$opt{title} = $kt;
			$opt{directory} = $kd;
			$self->{options}->{directory} = $kd;
			$self->{options}->{title} = $kt;
			$MSG_PROMPT = $km;
		}
	}
	my $config_dir = $CONFIG_DIR;
	if($opt{config}) {
		$config_dir = $opt{config};
	}

	my (@queue,@done,@failed,@ignore,@input);
	my %duplicated;

	@input = $self->_read_lines($opt{input}) if($opt{input});
	push @input,@arguments;
	$COUNTALL = scalar(@input);
	if($opt{simple}) {
		push @queue,@input;
	}
	elsif(-d $config_dir) {
		@done = $self->_read_lines($DB_DONE,$config_dir) unless($opt{'no-done'});
		@failed = $self->_read_lines($DB_FAILED,$config_dir) unless($opt{'no-failed'});
		@ignore = $self->_read_lines($DB_IGNORE,$config_dir) unless($opt{'no-ignored'});
		my @dup;
		push @queue, $self->_read_lines($DB_QUEUE,$config_dir) unless($opt{'no-queue'});
		$COUNTALL = scalar(@queue) + $COUNTALL;
		if($opt{'no-unique'}) {
			unshift @queue,@input;
		}
		elsif($opt{'no-strict-url'}) {
			unshift @queue, unique(\@input,\@dup,@queue,@failed,@done,@ignore) if(@input);
		}
		else {
			@queue = unique([@queue,@input],\@dup,@failed,@done,@ignore) if(@queue or @input);
		}
		#&_write_lines(\@queue,$DB_QUEUE,$config_dir);
		#	die(@queue);

		if($opt{retry}) {
			my @newfailed;
			foreach(@failed) {
				if($opt{include} and $_ !~ m/$opt{include}/) {
					push @newfailed,$_;
					next;
				}
				elsif($opt{exclude} and $_ =~ m/$opt{exclude}/) {
					push @newfailed,$_;
					next;
				}
				print STDERR $_,"\n";
				unshift @queue,$_;
			}
			@failed = @newfailed;
			&_write_lines(\@failed,$DB_FAILED,$config_dir);
		}
	}
	elsif(!(@queue or @input)) {
		return $self->exit($CWD_KEPT,$COUNTER);
	}
	elsif($opt{'no-unique'}) {
		unshift @queue,@input;
	}
	elsif($opt{'no-strict-url'}) {
		unshift @queue, unique(\@input,undef,@queue) if(@input);
	}
	else {
		@queue = unique([@queue,@input],undef) if(@queue or @input);
	}
	&_write_lines(\@queue,$DB_QUEUE,$config_dir);
	if($opt{include}) {
		@queue = grep(/$opt{include}/,@queue);
	}
	if($opt{exclude}) {
		@queue = grep(!/$opt{exclude}/,@queue);
	}
	if(defined $opt{select}) {
		print STDERR "Select tasks [$opt{select}]\n";
		my ($a1,$a2) = ($opt{select},$opt{select});
		if($a1 =~ m/^(\d+)\s*[-\. ]+\s*(\d+)$/) {
			$a1 = $1;
			$a2 = $2;
		}
		$a1--;
		$a2--;
		if($a1 >=0 and $a2<=$#queue) {
			@queue = @queue[$a1 .. $a2];
		}
		else {
			@queue = ();
		}
	}
	my $count = scalar(@queue);
	if($opt{count}) {
		if($opt{count}>0 and $count>=$opt{count}) {
			@queue = @queue[0 .. ($opt{count}-1)];
			$count = scalar(@queue);
		}
		else {
			print STDERR "Invalid option count specified as $opt{count}\n";
		}
	}
	p_msg "QUEUE:" . scalar(@queue) .
		  ", DONE :" . scalar(@done) . 
		  ", IGNORED: " . scalar(@ignore) . 
		  ", FAILED: " . scalar(@failed) .
	      "\n";
	print STDERR ">>> COUNTALL = $COUNTALL, queue = " . scalar(@queue) . "\n"; 
	$COUNTER = $COUNTALL - scalar(@queue);
	if(!$count) {
		&p_warn("Tasks queue was empty\n") unless($opt{quiet});
		return $self->exit($CWD_KEPT,$COUNTER,$self->EXIT_CODE('IGNORED'),"Empty tasks queue");
	}
	elsif($opt{simple}) {
	}
	elsif((! -d $config_dir)) {
		if(! mkdir $config_dir) {
			p_err "Error creating directory <$config_dir>: $!\n";
		}
	}
	
	my @wopts;
	push @wopts,'--overwrite' if($opt{overwrite});
	push @wopts,"--force" if($opt{force});
	push @wopts,"--referer",$opt{referer} if($opt{referer});
	push @wopts,"--referer",$self->{source}->{referer} if($self->{source}->{referer});

	my $IAMKILLED = undef;
	
	my $SUBEXIT = sub {
		if(!$opt{simple}) {
			print STDERR "\n";
			if(!-d $config_dir) {
				if(!mkdir($config_dir)) {
					&p_warn("Error creating directory $config_dir: $!\n");
				}
			}
			#&_write_lines(\@done,$DB_DONE,$config_dir);
			&_write_lines(\@queue,$DB_QUEUE,$config_dir);
			if($opt{'ignore-failed'}) {
				&_write_lines([@ignore,@failed],$DB_FAILED,$config_dir);
			}
#			else {
#					&_write_lines(\@failed,$DB_FAILED,$config_dir);
#			}
		}
		return $self->exit(
			$CWD_KEPT,
			$COUNTER,
			($IAMKILLED ? 
				($self->EXIT_CODE('KILLED'),"KILLED") : 
				($self->EXIT_CODE("OK"),"OK")
			)
		);
	};	
	my $SIGINT = $SIG{INT};
	$SIG{INT} = sub {
		delete $SIG{INT};
		return 2 if($IAMKILLED);
		$IAMKILLED = 1;
		print STDERR "MyPlace::Tasks::Manager KILLED\n";
		return 2;
	};
	if($opt{print}) {
		$opt{nop} = 1;
		my $n = 1;
		my $a2 = scalar(@queue);
		print STDERR "$a2 tasks in queue:\n";
		foreach(@queue) {
			print STDERR " [$n/$a2] $_\n";
			$n++;
		}
	}
	if($opt{nop}) {
		return $self->exit($CWD_KEPT,0,$self->EXIT_CODE("NOP"),"NOP");
	}
	#print STDERR "Touching directories ...\n";
	touch_path(getcwd);	

	my $index = 0;
	

	while($queue[0]) {
		last if($IAMKILLED);
		last if($opt{nop});
		my $task = $queue[0];
		my $r;
		$index++;
		&p_prompt("[$index/$count] $queue[0]\n");
		if($task =~ m/^#/) {
			if($task =~ m/^#([^:]+?)\s*:\s*(.*)$/) {
				p_msg "$1 : $2\n";
			}
			else {
				p_msg $task,"\n";
			}
			$r = $self->EXIT_CODE("DEBUG");
		}
		elsif($opt{mark}) {
			if($opt{mark} eq 'done') {
				$r = 0;
			}
			elsif($opt{mark} eq 'ignored') {
				$r = $self->EXIT_CODE('IGNORED');
			}
			elsif($opt{mark} eq 'failed') {
				$r = $self->EXIT_CODE('FAILED');
			}
			else {
				$r = $self->EXIT_CODE('UNKNOWN');
			}
		}
		elsif(ref $worker) {
			$r = &$worker($task,@wopts);
		}
		else {
			$r = system($worker,$task,@wopts);
			if($r != 0 and $r != 2) {
				$r = $r>>8;
			}
		}
#		print STDERR ("EXIT_CODE[$r]\n");
		last if($IAMKILLED);
		sleep 1;
		last if($IAMKILLED);
		if($r == 0) {
			#	&p_msg("[$index/$count] DONE\n");
			$COUNTER++;
			shift @queue;
			&_write_lines([$task],$DB_DONE,$config_dir,'>>');
			push @done,$task;
		}
		elsif($r == 2) {
			$IAMKILLED = 1;
			print STDERR ("I AM KILLED\n");
			last;
		}
		elsif($r == 12) {
			$COUNTER++;
			shift @queue;
			&_write_lines([$task],$DB_DONE,$config_dir,'>>');
			push @done,$task;
		}
		elsif($r == $self->EXIT_CODE('IGNORED')) {
			#	&p_msg("[$index/$count] IGNORED\n");
				$COUNTER++;
				shift @queue;
				&_write_lines([$task],$DB_DONE,$config_dir,'>>');
				push @done,$task;
		}
		elsif($r == $self->EXIT_CODE("DEBUG")) {
			shift @queue;
		}
		elsif($r == $self->EXIT_CODE("UNKNOWN")) {
			shift @queue;
		}
		else {
			shift @queue;
			#&p_msg("[$index/$count] FAILED\n");
			&_write_lines([$task],$DB_FAILED,$config_dir,'>>');
			push @failed,$task;
		}
		unless($opt{quiet} or $opt{simple}) {
			p_msg "QUEUE:" . scalar(@queue) .
				  ", DONE :" . scalar(@done) . 
				  ", IGNORED: " . scalar(@ignore) . 
				  ", FAILED: " . scalar(@failed) .
			"\n";
		}
		last if($IAMKILLED);
	}
	$SIG{INT} = $SIGINT;
	return &$SUBEXIT();
}

sub exit {
	my $self = shift;
	return @{$self->{exited}} if(defined $self->{exited});
	my %opt = %{$self->{options}};
	if($opt{include}) {
		p_msg "INCLUDE: " . $opt{include} . "\n";
	}
	if($opt{exclude}) {
		p_msg "EXCLUDE: " . $opt{exclude} . "\n";
	}
	my $CWD_KEPT = shift;
#	if($CWD_KEPT) {
#		#	p_msg "Return to directory:$CWD_KEPT\n" unless($opt{simple} or $opt{quiet});
#		if(!chdir $CWD_KEPT) {
#			p_err "Error:$!\n";
#			$self->{exited} = [undef,4,"$!"];
#		}
#	}
	$self->{exited} = [@_];
	return @{$self->{exited}};
}

1;

