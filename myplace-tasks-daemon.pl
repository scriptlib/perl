#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::myplace_tasks_daemon;
use warnings;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
/;
my %OPTS;
if(@ARGV)
{
    require Getopt::Long;
    Getopt::Long::GetOptions(\%OPTS,@OPTIONS);
}
if($OPTS{'help'} or $OPTS{'manual'}) {
	require Pod::Usage;
	my $v = $OPTS{'help'} ? 1 : 2;
	Pod::Usage::pod2usage(-exitval=>$v,-verbose=>$v);
    exit $v;
}


use MyPlace::Script::Message;
use MyPlace::Tasks::Utils qw/strtime/;
use MyPlace::Tasks::Center::Git;
use MyPlace::Tasks::Listener;
use MyPlace::Tasks::Worker;


sub urlrule_sites_from_url {
	my $url = shift;
	my $name;
	my $id;
	my $host;
	$url =~ s/weipai\.cn\/(?:videos|user)\//weipai.cn\/follows\//;
	open FI,'-|','netcat',$url or return;
	while(<FI>) {
		chomp;
		if(!$host) {
			if(m/'LoginDownloadUrl'\s*:\s*'http:\/\/www.weipai.cn\/coop/) {
				$host = "weipai.cn";
			}
		}
		if(!$name) {
			if(m/class="name"[^>]*title="([^"]+)"/) {
				$name = $1;
			}
		}
		if(!$id) {
			if(m/href="\/user\/([^"]+)/) {
				$id = $1;
			}
		}
		last if($id and $name);
	}
	close FI;
	#print STDERR "$name === $id\n";
	return $host,$name,$id;
}

my $WORKER = MyPlace::Tasks::Worker->new(
	name=>'urlrule',
	routine=>sub{
		my $type = shift;
		if($type eq 'sites') {
			my $hosts = shift;
			my $name = shift;
			my $id = shift;
			my $url;
			if(!-d "ladies") {
				mkdir "ladies";
			}
			chdir "ladies";
			if(uc($hosts) eq 'FROMURLS') {
				$url = $name;
				($hosts,$name,$id) = urlrule_sites_from_url($url,$id,@_);
				if(!($id and $name and $hosts)) {
					app_error "Invalid information read from <$url>\n";
					return;
				}
				app_message "From $url: $hosts/$name/$id\n";
				system("urlrule_sites","--hosts",$hosts,"--add","$id\t$name");
			}
			if($id) {
				system("urlrule_sites","--hosts",$hosts,$id);
			}
			elsif($name) {
				system("urlrule_sites","--hosts",$hosts,$name);
			}
			else {
				system("urlrule_sites","--hosts",$hosts);
			}
			return join(": ",
				"[urlrule::sites] Saved", 
				join(" ",$id,"[$name]",($url ? "($url)" : undef))
			);
		}
		else {
			print STDERR "Worker[urlrule] not support type\n";
			return "[urlrule] Error $type not support";
		}
	},
);

my @LISTENER = (
	MyPlace::Tasks::Listener->new('urlrule',$WORKER),
	MyPlace::Tasks::Listener->new('overjoy',MyPlace::Tasks::Worker->new(
		name=>'overjoy',
		routine=>sub{
			my $type = shift;
			if($type eq 'ladies') {
				my @names = @_;
				if(@names) {
					chdir "/myplace/overjoy/ladies";
					system("urlrule_task","SAVE",@names);
				}
			}
		},
	)),
	MyPlace::Tasks::Listener->new('download',MyPlace::Tasks::Worker->new(
		name=>'download',
		routine=>sub{
			my $dir= shift;
			mkdir "download" unless(-d "download");
			$dir = "download/$dir";
			mkdir $dir unless(-d $dir);
			chdir $dir;
			my $r = (system('download',@_) == 0);
			if($r) {
			}
			else {
			}
			return $r;
		},
	)),
	MyPlace::Tasks::Listener->new('dump', 
		MyPlace::Tasks::Worker->new(
				name=>'dump',
				routine=>sub{
					use Data::Dumper;
					print STDERR Data::Dumper->Dump(\@_);
				}
		)
	),
	MyPlace::Tasks::Listener->new('exec',
		MyPlace::Tasks::Worker->new(
			name=>'exec',
			routine=>sub{
				my @result;
				open FI,'-|',@_ or return "$!";
				@result = <FI>;
				close FI;
				return join("",@result);
			}
		)
	),
);



my $TASKER = MyPlace::Tasks::Center::Git->new();

sub abort {
	$TASKER->abort();
	print STDERR "Program killed\n";
	exit $TASKER->exit();
}
$SIG{INT} = \&abort;

app_message "[" . strtime() . "] Start\n";
app_message "[" . strtime() . "] Waiting for event\n";
my $count =0;
while(!$TASKER->end()) {
	my $remain;
	if ($remain = $TASKER->more()) {
		my $task = $TASKER->next();
		$task->{status} = 0;
		my $status = 0;
#		print STDERR join("\n",$TASKER->status),"\n";
		app_message "Tasks $count DONE, $remain REMAIN:\n";
		print STDERR join("\n",$TASKER->status()),"\n";
		app_message "Current task:" . $task->to_string . "\n";
		foreach my $listener (@LISTENER) {
			if($listener->check($task)) {
				if($listener->fire_event($task)) {
					$task->{status} = 1;
					$status = 1;
				}
				else {
					$task->{status} = 2;
					$status = 2;
				}
			}
		}
		$TASKER->finish($task,$status);
	}
	else {
		app_message "[" . strtime() . "] Waiting for event\n" 
	}
} 
exit $TASKER->exit();



























#	vim:filetype=perl



__END__

=pod

=head1  NAME

myplace-tasks-daemon - PERL script

=head1  SYNOPSIS

myplace-tasks-daemon [options] ...

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

    2014-08-30 01:29  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
