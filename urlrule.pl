#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::urlrule;
use base 'MyPlace::Program';
use strict;
use warnings;
use MyPlace::URLRule::Database;
use MyPlace::URLRule::SimpleQuery;
use File::Spec::Functions qw/catdir catfile/;
my $MSG_PROMPT = 'URLRULE';

my %EXIT_CODE = qw/
	OK			0
	FAILED		1
	DO_NOTHING	2
	ERROR_USAGE 3
/;

sub VERSION {'v0.1'}
sub OPTIONS {qw/
	help|h|? 
	manual|man
	hosts=s
	database|db
	all|a
	thread=i
	retry
	prompt|p=s
	url|u
/}






sub p_out {
	print @_;
}

sub p_msg {
	print STDERR "$MSG_PROMPT> ",@_;
}

sub p_err {
	print STDERR "$MSG_PROMPT> ",@_;
}

sub p_warn {
	print STDERR "$MSG_PROMPT> ",@_;
}

sub check_trash {
	my $path = shift;
	foreach('#Empty','#Trash') {
		my $dir = $_ . "/" . $path;
		if(-d $dir) {
			print STDERR "[$path] in [$_] IGNORED!\n";
			return undef;
		}
	}
	return 1;
}

sub DB_INIT {
	my $self = shift;
	my %OPTS = %{$self->{OPTS}};
	return if($OPTS{url});
	$OPTS{all} = 1 unless($OPTS{hosts} or $OPTS{database});
	if($OPTS{all}) {
		$OPTS{hosts} = "*";
		$OPTS{database} = "";
	}
	if(defined($OPTS{hosts})) {
		$self->{USQ} = MyPlace::URLRule::SimpleQuery->new($OPTS{hosts});
	}
	if(defined($OPTS{database})) {
		$self->{DB} = [MyPlace::URLRule::Database->new()];
	}
	return $self;
}

sub query {
	my $self = shift;
	my %OPTS = %{$self->{OPTS}};
	if(!@_) {
		p_err "Nothing to do for nothing\n";
		return;
	}
	my @target;
	if($OPTS{url}) {
		push @target,{
			url=>$_[0],
			level=>($_[1] || 0),
			title=>($_[2] || ""),
		};
	}

	if($self->{USQ}) {
		my $USQ = $self->{USQ};
		foreach(@_) {
			my ($status,@result) = $USQ->query($_);
			if($status) {
				foreach my $item (@result) {
					push @target,{
						host=>$item->[4],
						id=>$item->[0],
						name=>$item->[1],
						url=>$item->[2],
						level=>$item->[3],
					}
				}
			}
		}	
	}
	if($self->{DB} and @{$self->{DB}}) {
		foreach my $USD (@{$self->{DB}}) {
			foreach(@_) {
				my ($status,@result) = $USD->query($_);
				push @target,@result if($status);
			}
		}
	}
	if(!@target) {
		p_err "Query \"@_\" match nothing!\n";
	}
	return @target;
}

sub CMD_LIST {
	my $self = shift;
	my %OPTS = %{$self->{OPTS}};
	my @target = @_;
	if(!@target) {
		return 1;
	}
	my $idx = 1;
	foreach(@target) {
		printf "[%03d]%-15s %30s [%d] %s\n",
				$idx,
				($_->{host} ? '<' . $_->{host} . '>' : '<URL>'),
				$_->{url},
				$_->{level},
				($_->{name} || "");
		$idx++;
	}
	return 0;
}

sub CMD_ACTION {
	my $self = shift;
	my %OPTS = %{$self->{OPTS}};
	my $cmd = shift(@_) || "UPDATE";
	my @target = @_;
	use MyPlace::URLRule::OO;
	my @request;
	my $count = 0;
	my %r;
	foreach my $item (@target) {
		if(!$item->{host}) {
			push @request,{
				count=>1,
				level=>$item->{level},
				url=>$item->{url},
				title=>$item->{title},
			};
			$count++;
			next;
		}
		my $dbname = $item->{host};
		if($dbname =~ m/^.+\|([^\|]+)$/) {
			$dbname = $1;
		}
		next unless($dbname);
		my $title = catdir($item->{name},$dbname);
		next unless(check_trash($title));
		push @request,{
			count=>1,
			level=>$item->{level},
			url=>$item->{url},
			title=>$title,
		};
		push @{$r{directory}},$title;
		$count++;
	}
	my $idx = 0;
	my $URLRULE = new MyPlace::URLRule::OO('action'=>$cmd,'thread'=>$OPTS{thread});
	foreach(@request) {
		$idx++;
		$_->{progress} = "[$idx/$count]";
		$URLRULE->autoApply($_);
		$URLRULE->reset();
	}
	if($URLRULE->{DATAS_COUNT}) {
		return $EXIT_CODE{OK},\%r;
	}
	else {
		return $EXIT_CODE{DO_NOTHING},\%r;
	}
}

sub CMD_DOWNLOAD {
	my $self = shift;
	my %OPTS = %{$self->{OPTS}};
	my @target = @_;
	my @request;
	my $count = 0;
	my %r;
	$self->CMD_ACTION('DATABASE',@target);
	use MyPlace::Program::Downloader;
	my $DL = new MyPlace::Program::Downloader;
	my @DLOPT = qw/--quiet --input urls.lst --recursive/;
	push @DLOPT,"--retry" if($OPTS{retry});

	foreach my $item (@target) {
		if($item->{host}) {
			my $dbname = $item->{host};
			if($dbname =~ m/^.+\|([^\|]+)$/) {
				$dbname = $1;
			}
			next unless($dbname);
			my $title = catdir($item->{name},$dbname);
			next unless(check_trash($title));
			push @request,$title;
			push @{$r{directory}},$title;
		}
		else {
			push @{$r{directory}},($item->{title} || ".");
		}
		$count++;
	}
	my $idx = 0;
	my $dlcount = 0;
	foreach(@request) {
		$idx++;
		my ($done,$error,$msg) = $DL->execute(@DLOPT,'--directory',$_,);
		if($done) {
			$dlcount += $done;
		}
		elsif($error) {
			print STDERR "Error($error): $msg\n";
		}
	}
	if($dlcount > 0) {
		return $EXIT_CODE{OK},\%r;
	}
	else {
		return $EXIT_CODE{DO_NOTHING},\%r;
	}
}

sub CMD_DUMP {
	my $self = shift;
	my @target = @_;
	foreach(@target) {
		system("urlrule_dump",$_->{url},($_->{level} || 0));
	}
	return $EXIT_CODE{OK};
}


sub MAIN {
	my $self = shift;
	my $OPTS = shift;
	$MSG_PROMPT = $OPTS->{prompt} if($OPTS->{prompt});
	$self->{OPTS} = $OPTS;
	my $cmd = shift;
	my $CMD = uc($cmd);
	my $EXIT = 0;
	if($CMD eq 'HELP') {
		exit 0;
	}
	$self->DB_INIT();
	my @target = $self->query(@_);
	if(!@target) {
		exit 1;
	}
	if($CMD eq 'LIST') {
		return $self->CMD_LIST(@target);
	}
	elsif($CMD eq 'DOWNLOAD') {
		return $self->CMD_DOWNLOAD(@target);
	}
	elsif($CMD eq 'UPDATE') {
		return $self->CMD_ACTION('DATABASE',@target);
	}
	elsif($CMD eq '!UPDATE') {
		return $self->CMD_ACTION('!DATABASE',@target);
	}
	elsif($CMD eq 'DUMP') {
		return $self->CMD_DUMP(@target);
	}
	else {
		p_err "Command not found: $cmd\n";
	}
	return $EXIT;
}

return 1 if caller;
my $PROGRAM = new MyPlace::Script::urlrule;
my ($exitval) = $PROGRAM->execute(@ARGV);
exit $exitval;


1;


__END__

=pod

=head1  NAME

urlrule - PERL script

=head1  SYNOPSIS

urlrule [options] ...

=head1  OPTIONS

=over 12

=item B<--version>

Print version infomation.

=item B<-h>,B<--help>

Print a brief help message and exits.

=item B<--manual>,B<--man>

View application manual

=item B<--edit-me>

Invoke 'editor' against the source

=back

=head1  DESCRIPTION

___DESC___

=head1  CHANGELOG

    2015-02-01 00:43  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
