#!/usr/bin/perl -w
package MyPlace::Program::SimpleQuery;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.10;
    @ISA            = qw(Exporter);
    @EXPORT         = qw();
    @EXPORT_OK      = qw(&validate_item &show_directory);
}
use strict;
use warnings;
use File::Spec::Functions qw/catfile/;
use Getopt::Long;
use MyPlace::URLRule::SimpleQuery;
use Getopt::Long qw/GetOptionsFromArray/;
use MyPlace::Script::Message;


my %EXIT_CODE = qw/
	OK			0
	FAILED		1
	DO_NOTHING	2
	ERROR_USAGE 3
/;


my $DEFAULT_HOST = "weibo.com,weipai.cn,vlook.cn,google.search.image,moko.cc";
my @DEFAULT_HOST = split(/\s*,\s*/,$DEFAULT_HOST);
my @OPTIONS = qw/
		help|h
		manual|man
		list|l
		force
		debug|d
		database|hosts|sites|db=s
		command|c:s
		update|u
		add|a
		additem
		saveurl=s
		overwrite|o
		thread|t:i
		file|f=s
		retry
		no-recursive|nr
		no-createdir|nc
		fullname
		no-download
		include|I:s
		exclude|X:s
		force-action|fa
		item
/;

sub new {
	my $class = shift;
	my $self = bless {},$class;
	if(@_) {
		$self->set(@_);
	}
	return $self;
}

sub cathash {
	my $lef = shift;
	my $rig = shift;
	return $lef unless($rig);
	return $lef unless(%$rig);
	my %res = $lef ? %$lef : ();
	foreach(keys %$rig) {
		$res{$_} = $rig->{$_} if(defined $rig->{$_});
	}
	return \%res;
}

sub set {
	my $self = shift;
	my %OPT;
	if(@_) {
		GetOptionsFromArray(\@_,\%OPT,@OPTIONS);
	}
	else {
		$OPT{'help'} = 1;
	}
	$self->{_OPTIONS} = cathash($self->{_OPTIONS},\%OPT);
	$self->{_ARGV} = @_ ? [@_] : undef;
}


sub do_list {
	my $self = shift;
	my @target = @_;
	my $idx = 1;
	foreach(@target) {
		my @rows = @$_;
		my $host = shift(@rows) || '*';
		print STDERR "[" . uc($host),"]:\n";
		foreach my $item(@rows) {
			my $dbname = $item->[4] || $host;
			printf "%-20s: [%03d] %-20s [%d]  %s\n",$dbname,$idx,$item->[2],$item->[3],$item->[1];
			$idx++;
		}
	}
	return $EXIT_CODE{OK};
}

sub validate_item {

	my @teststr;
	foreach(@_) {
		push @teststr,$_ if($_);
	}
	my $testname = join(" ",@teststr);
	my $result = 1;
	return 1 unless(@teststr);

	foreach(@teststr) {
		next if(!$_);
		if(m/^#Trash/i) {
			&app_error("[$testname] in catalog <#Trash>, Ignored\n");
			return undef;
		}
	}



	my %TRASHED;
	if(open FI,'<','#TRASH.txt') {
		foreach(<FI>) {
			chomp;
			s/\/+$//;
			$TRASHED{$_} = 1;
		}
		close FI;
	}

	foreach(@teststr) {
		s/\/+$//;
		if(defined $TRASHED{$_}) {
			&app_error("[$testname] in file <#TRASH.txt>, Ignored.\n");
			return undef;
		}
	}

	foreach('#Empty','#Trash') {
		foreach my $path(@teststr) {
			my $dir = $_ . "/" . $path;
			if(-d $dir) {
				print STDERR "[$testname] in directory [$_], Ignored.\n";
				return undef;
			}
		}
	}
	return 1;
}
sub get_request {
	my $self = shift;
	my $OPTS = $self->{options};
	my @target = @_;
	my $count = 0;
	my @request;
	my %r;
	foreach(@target) {
		my @rows = @$_;
		my $host = shift(@rows) || '*';
		foreach my $item(filter_items(@rows)) {
			next unless($item && ref $item && @{$item});
			my $dbname = $item->[4] || $host;
			my $title = $OPTS->{createdir} ? $item->[1] . "/$dbname/" : "";
			push @request,{
				count=>1,
				level=>$item->[3],
				url=>$item->[2],
				title=>$title,
				root_dir=>$item->[1],
			};
			push @{$r{directory}},$title if($title);
			$count++;
		}
	}
	return $count,\%r,@request;
}
sub show_directory {
	my $dir = shift;
	if(-l $dir) {
		my $link = readlink($dir);
		print STDERR "\n";
		&app_message2("Working in directory: $dir (symbol link)\n\t=>$link\n");
	}
	else {
		print STDERR "\n";
		&app_message2("Working in directory: $dir\n");
	}
}

sub do_action {
	my $self = shift;
	my $action = shift;
	my $OPTS = $self->{options};
	my @target = @_;
	use MyPlace::URLRule::OO;
	my ($count,$r,@request) = $self->get_request(@target);
	my $idx = 0;
#    use Data::Dumper;
#   print STDERR Data::Dumper->Dump([$OPTS],qw/*OPTS/),"\n";
	my $URLRULE = new MyPlace::URLRule::OO(
			'action'=>$action,
			'thread'=>$OPTS->{thread},
			'createdir'=>$OPTS->{createdir},
			'options'=>{
				fullname=>$OPTS->{fullname},
			},
			'include'=>$OPTS->{include},
			'exclude'=>$OPTS->{exclude},
	);
	foreach(@request) {
		$idx++;
		$_->{progress} = "[$idx/$count]";
		if($_->{root_dir}) {
			show_directory($_->{root_dir});
		}
		$URLRULE->autoApply($_);
		$URLRULE->reset();
	}
	if($URLRULE->{DATAS_COUNT}) {
		return $EXIT_CODE{OK},$r;
	}
	else {
		return $EXIT_CODE{DO_NOTHING},$r;
	}
}

sub do_search {
}
sub filter_items {
	my @items;
	foreach my $item(@_) {
		if(ref $item) {
			next unless(validate_item($item->[0],$item->[1]));	
		}
		else {
			next unless(validate_item($item));
		}
		push @items,$item;
	}
	return @items;
}

sub do_downloader {
	my $self = shift;
	my @target = @_;
	my $OPTS = $self->{options};
	my @request;
	my $count = 0;

	my %r;
	
	if((!$OPTS->{force}) and $OPTS->{'no-download'}) {
		return $self->do_action('DATABASE',@target);
	}	
	$self->do_action('DATABASE',@target);

	use MyPlace::Program::Downloader;
	my $DL = new MyPlace::Program::Downloader;
	my @DLOPT = qw/--quiet --input urls.lst/;
	push @DLOPT,"--recursive" if($OPTS->{recursive});
	#push @DLOPT,"--retry" unless($OPTS->{'no-retry'});
	push @DLOPT,"--retry" if($OPTS->{retry});
	#unless($OPTS->{'no-retry'});
	push @DLOPT,'--include',$OPTS->{include} if($OPTS->{include});
	push @DLOPT,'--exclude',$OPTS->{exclude} if($OPTS->{exclude});
	
	if($OPTS->{createdir}) {
		foreach(@target) {
			my @rows = @$_;
			my $host = shift(@rows);
			foreach my $item(filter_items(@rows)) {
				next unless($item && @{$item});
				my $dbname = $item->[4] || $host;
				my $title = $item->[1] . "/$dbname";# . $item->[0];
				push @request,$title;
				push @{$r{directory}},$title;
				$count++;
			}
		}
	}
	else {
		@request = ("");
	}
	my $idx = 0;
	my $dlcount = 0;
	foreach(@request) {
		$idx++;
		my @PROGOPT = @DLOPT;
		push @PROGOPT,"--directory",$_ if($_);
		my ($done,$error,$msg) = $DL->execute(@PROGOPT);
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

sub do_update {
	my $self = shift;
	my $cmd = shift(@_) || "UPDATE";
	if((!$self->{options}->{force}) and $self->{options}->{'no-download'}) {
		$cmd = 'DATABASE' if($cmd =~ m/^(?:SAVE|UPDATE|DOWNLOADER|DOWNLOAD)$/i);
	}
	unshift @_,$self,$cmd;
	goto &do_action;
}


sub do_file {
	my $self = shift;
	my $output = shift;
	unshift @_,"DATABASE:$output";
	goto &do_action;
}

sub do_add {
	my $self = shift;
	my $COMMAND = shift(@_) || $self->{COMMAND};
	my $NAMES = shift(@_) || $self->{NAMES};
	my $DATABASE = shift(@_) || $self->{DATABASE};
	my $OPTS = $self->{options};
	my $r = $EXIT_CODE{OK};
	if(!$NAMES) {
		print STDERR "Arguments requried for COMMAND <add>\n";
		$r = $EXIT_CODE{ERROR_USAGE};
	}
	else {
		foreach my $db (@$DATABASE) {
			my $SQ;
			if($OPTS->{overwrite}) {
				$SQ = MyPlace::URLRule::SimpleQuery->new([$db,'overwrite']);
			}
			else {
				$SQ = MyPlace::URLRule::SimpleQuery->new($db);
			}
			my ($count,$msg);
			if($COMMAND eq 'ADD') {
				($count,$msg) = $SQ->add(@$NAMES);
			}
			else {
				($count,$msg) = $SQ->additem(@$NAMES);
			}
			#print STDERR "SimpleQuery Add ",join(", ",$count,$msg),"\n";
			if($count) {
				$SQ->save;
				$r = $EXIT_CODE{OK};
			}
			else {
				$r = $EXIT_CODE{DO_NOTHING};
			}
		}
	}
	return $r;
}


sub do_upgrade {
	my $self = shift;
	my $COMMAND = shift(@_) || $self->{COMMAND};
	my $NAMES = shift(@_) || $self->{NAMES};
	my $DATABASE = shift(@_) || $self->{DATABASE};
	my $OPTS = $self->{options};
	if(!$NAMES) {
		print STDERR "Arguments requried for COMMAND <_UPGRADE>\n";
		return $EXIT_CODE{ERROR_USAGE};
	}
	my $SRCD = $OPTS->{srcd} || ".";
	my $DSTD = $OPTS->{dstd} || "_upgrade";
	foreach my $db (@$DATABASE) {
		my $SQ = MyPlace::URLRule::SimpleQuery->new($db);
		foreach(@$NAMES) {
			my($id,$name) = $SQ->item($_);
			if($id and $name) {
				my $src = catfile($SRCD,$_);
				my $dstd = catfile($DSTD,"$_/$db");
				print STDERR "\"$src\" => \"$dstd/$id\"\n";
				system('mkdir','-p','--',$dstd) unless(-d $dstd);
				system('mv','-v','--',$src,catfile($dstd,$id));
				print STDERR "\n";
			}
			else {
				print STDERR "Id not found for \"$_\"\n";
			}
		}
	}
	return $EXIT_CODE{OK};
}

sub do_saveurl {
	my $self = shift;
	my $COMMAND = shift(@_) || $self->{COMMAND};
	my $NAMES = shift(@_) || $self->{NAMES};
	my $DATABASE = shift(@_) || $self->{DATABASE};
	my $OPTS = $self->{options};
		my $SQ = MyPlace::URLRule::SimpleQuery->new($DATABASE->[0]);
		my($id,$name) = $SQ->item(@$NAMES);
		my $DATABASENAME = $DATABASE->[0];
		if(!$id) {
			print STDERR "Error: ",$name,"\n";
			return $EXIT_CODE{FAILED};
		}
		if(!validate_item($id,$name)) {
			return $EXIT_CODE{DO_NOTHING};
		}
		use MyPlace::URLRule::OO;
		my $action = $OPTS->{'force'} ? 'DOWNLOAD' : $OPTS->{'no-download'} ? 'DATABASE' : 'DOWNLOAD';
		$action = '!' . $action  if($OPTS->{'force-action'});
		my $URLRULE = new MyPlace::URLRule::OO(
				'action'=>'SAVE',#$action,
				'thread'=>$OPTS->{thread},
				'createdir'=>$OPTS->{createdir},
				'include'=>$OPTS->{include},
				'exclude'=>$OPTS->{exclude},
		);
		if($name) {
			show_directory($name);
		}
		$URLRULE->autoApply({
				count=>1,
				level=>0,
				url=>$OPTS->{saveurl},
				title=> $OPTS->{createdir} ? join("/",$name,$DATABASENAME,$id) : '',
		});
		if($URLRULE->{DATAS_COUNT}) {
			if($OPTS->{createdir}) {
				return $EXIT_CODE{OK},{'directory'=>["$name/$DATABASENAME"]};
			}
			else {
				return $EXIT_CODE{OK};
			}
		}
		else {
			return $EXIT_CODE{DO_NOTHING};
		}
}

sub query {
	my $self = shift;
	my $NAMES = shift(@_) || $self->{NAMES};
	my $DATABASE = shift(@_) || $self->{DATABASE};
	my $OPTS = $self->{options};
	my @target;
	foreach my $db (@$DATABASE) {
		my $SQ = new MyPlace::URLRule::SimpleQuery($db);
		if(!$NAMES) {
			my($status,@result) = $SQ->all();
			if(!$status) {
				print STDERR "[$db] Error: ",@result,"\n";
			}
			else {
				push @target,[$db,@result];
			}
		}
		elsif($OPTS->{item}) {
			foreach my $keyword(@$NAMES) {
				my($status,@result) = $SQ->find_item($keyword);
				if(!$status) {
					print STDERR "[$db] Error: ",@result,"\n";
				}
				else {
					push @target,[$db,@result];
				}
			}
		}
		else {
			foreach my $keyword (@$NAMES) {
				my($status,@result) = $SQ->query($keyword);
				if(!$status) {
					print STDERR "[$db] Error: ",@result,"\n";
				}
				else {
					push @target,[$db,@result];
				}
			}
		}
		$SQ = undef;
	}
	return @target;
}

sub process_target {
	my $self = shift;
	my $cmd = shift(@_) || $self->{COMMAND};
	if($cmd eq 'LIST') {
		my @target = $self->query();
		return $self->do_list(@target);
	}
	elsif($cmd eq 'FILE') {
		my @target = $self->query();
		return $self->do_file($self->{options}->{file},@target);
	}
	elsif($cmd eq 'DOWNLOADER') {
		my @target = $self->query();
		return $self->do_downloader(@target);
	}
	elsif($cmd eq 'SEARCH') {
		my @target = $self->query();
		return $self->do_search(@target);
	}
	else {
		my @target = $self->query();
		return $self->do_update($cmd,@target);
	}
#	else {
#		print STDERR "Error, COMMAND $cmd not supported!\n";
#		return $EXIT_CODE{ERROR_USAGE};
#	}
}

sub process_command {
	my $self = shift;
	my $COMMAND = shift(@_) || $self->{COMMAND};
	if($COMMAND eq 'ADD' || $COMMAND eq 'ADDITEM') {
		return $self->do_add($COMMAND);
	}
	elsif($COMMAND eq '_UPGRADE') {
		return $self->do_upgrade($COMMAND);
	}
	elsif($COMMAND eq 'SAVEURL') {
		return $self->do_saveurl($COMMAND);
	}
	else {
		return $self->process_target($self->{COMMAND});
	}

}

	sub build_host_url {
		my $host = uc(shift(@_));
		my $id = shift;
		if($host eq 'WEIPAI.CN') {
			return "http://w1.weipai.cn/user_video_list?blog_id=$id";
		}
		elsif($host eq 'VLOOK.CN') {
			return "http://www.vlook.cn/user_video_list?blog_id=$id";
		}
		else {
			return $id;
		}
	}
	sub extract_info_from_url {
		my $url = shift;
		my $host = shift;
		if($url =~ m/weipai\.cn|l\.mob\.com/) {
			my ($host,$name,$id);
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
					elsif(m/"nickname"\s*[:=]\s*"([^"]+)/) {
						$name = $1;
						$name =~ s/\\u(\w{4,4})/chr(hex($1))/eg;
					}
				}
				if(!$id) {
					if(m/href="\/user\/([^\/"]+)/) {
						$id = $1;
					}
					elsif(m/"user_id"\s*[:=]\s*"([^"]+)/) {
						$id = $1;
					}
				}
				last if($id and $name);
			}
			close FI;
			return $id,$name,$host;
		}
		elsif($url =~ m/vlook\.cn/) {		
			my ($name,$id);
			open FI,'-|','netcat',$url or return;
			while(<FI>) {
				chomp;
				if(!$host) {
					$host = 'vlook.cn';
				}
				if(m/<a[^>]*href="\/mobile\/mta\/home\/qs\/([^"\/\?]+)[^"]*"[^>]*class="user"[^>]*>\s*([^<]+?)\s*<\/a/) {
					$name = $2;
					$id = $1;
					last;
				}
				elsif(m/<a[^>]*href="\/ta\/qs\/([^"\/\?]+)[^"]*"[^>]*name="card"[^>]*class="nick"[^>]*>\s*([^<]+?)\s*:\s*<\/a/) {
					$name = $2;
					$id = $1;
					last;
				}
				elsif(m/<a[^>]*href="\/ta\/qs\/([^"\/\?]+)[^"]*"[^>]*name="card"[^>]*class="nick"[^>]*>\s*([^<]+?)\s*<img/) {
					$name = $2;
					$id = $1;
					last;
				}
				
			}
			close FI;
			#die "[$url] => $name, $id\n";
			return $id,$name,$host;
		}
	}

sub parse_command {
	my $self = shift;

	my $host = shift;

	return undef,'No hosts specified' unless($host);

	my $URLRULE_SITES_COMMANDS_ALL = '^(?:AFU|AFS|FU|FS|AU|AS|ADD|FOLLOW|SAVE|SAVEURL|UPDATE|SAVEURLS)$';
	my $URLRULE_SITES_COMMANDS = '^(?:ADD|FOLLOW|SAVE|SAVEURL|UPDATE|SAVEURLS)$';

	my $NO_HOST_CMDS = /^(?:SAVEURL|SAVEURLS)$/i;

	my $cmd;
	if(uc($host) =~ $URLRULE_SITES_COMMANDS_ALL) {
		$cmd = $host;
	}
	else {
		$cmd = shift;
	}
	return undef,'No commands specified' unless(defined $cmd);

	

	my ($CMD,@CMDS_NEXT) = split(/\s*,\s*/,uc($cmd));
	if($CMD eq 'AFU') {
		$CMD = 'ADD';
		push @CMDS_NEXT,'FOLLOW','UPDATE';
	}
	elsif($CMD eq 'AFS') {
		$CMD = 'ADD';
		push @CMDS_NEXT,'FOLLOW','SAVE';
	}
	elsif($CMD eq 'FU') {
		$CMD = 'FOLLOW';
		push @CMDS_NEXT,'UPDATE';
	}
	elsif($CMD eq 'FS') {
		$CMD = 'FOLLOW';
		push @CMDS_NEXT,'SAVE';
	}
	elsif($CMD eq 'AU') {
		$CMD = 'ADD';
		push @CMDS_NEXT,'UPDATE';
	}
	elsif($CMD eq 'AS') {
		$CMD = 'ADD';
		push @CMDS_NEXT,'SAVE';
	}

	if($CMD !~ $URLRULE_SITES_COMMANDS) {
		return undef,"Invalid command specified: $cmd";
	}
	my $ARG1 = shift;
	return undef,"No arguments specified for cmd: $CMD" unless($ARG1);

	if($CMD =~ m/^SAVEURLS?$/) {
		if($ARG1 and $ARG1 !~ m/^http/) {
			$ARG1 = build_host_url($host,$ARG1);
		}
	}
	
	my $URL;
	my $URL_INFO;
	my $title;
	if($ARG1 and $ARG1 =~ m/^https?:/) {
			my ($key1,$key2,$key3) = extract_info_from_url($ARG1);
			if(!($key1 or $key2)) {
				return undef,'Extract information from URL failed '. $ARG1;
			}
			unshift @_,$key2 if($key2);
			unshift @_,$key1 if($key1);
			$host = $key3 if($key3);
			$URL = $ARG1;
			$URL_INFO = "[$key3] $key1 $key2";
			$title = "[urlrule sites/$key3] $CMD $key1 $key2";
	}
	else {
		unshift @_,$ARG1;
	}					

	return 1,{
		host=>$host,
		cmd=>$CMD,
		cmds_next=>\@CMDS_NEXT,
		url=>$URL,
		url_info=>$URL_INFO,
		args=>@_,
		description=>$title,
	};
}

sub execute_command {
	my $self = shift;
	my ($ok,$result) = $self->parse_command(@_);

	if(!$ok) {
		return 'ERROR',{message=>$result};
	}

	my $host = $result->{host};
	my $cmd = $result->{cmd};





}

sub execute {
	my $self = shift;
	my $OPT;
	my @argv;
	if(@_) {
		$OPT= {};
		GetOptionsFromArray(\@_,$OPT,@OPTIONS);
		$OPT = cathash($self->{_OPTIONS},$OPT);
		@argv = @_ if(@_);
	}
	else {
		$OPT = $self->{_OPTIONS};
		@argv = $self->{_ARGV} ? @{$self->{_ARGV}} : undef;
	}
	if($OPT->{help}) {
		pod2usage('-exitval'=>1,'-verbose'=>1);
		return $EXIT_CODE{OK};
	}
	elsif($OPT->{manual}) {
		pod2usage('--exitval'=>1,'-verbose'=>2);
		return $EXIT_CODE{OK};
	}
	foreach my $defkey(qw/createdir recursive/) {
		$OPT->{$defkey} = $OPT->{"no-$defkey"} ? 0 : 1;
	}
	$self->{NAMES} = @argv ? \@argv : undef;
	$self->{COMMAND} = 	$OPT->{additem} ? 'ADDITEM' : $OPT->{add} ? 'ADD' : $OPT->{list} ? 'LIST' : $OPT->{update} ? 'UPDATE' : $OPT->{file} ? 'FILE' : $OPT->{command} ? uc($OPT->{command}) : 'UPDATE';
	$self->{COMMAND} = "SAVEURL" if($OPT->{saveurl});
	$self->{DATABASE} = [$OPT->{database} ? split(/\s*,\s*/, $OPT->{database}) : @DEFAULT_HOST];
	$self->{options} = $OPT;

	######DISABLE FORCE MODE#####
	#delete $OPT->{force};

	return $self->process_command($self->{COMMAND});
}

return 1 if caller;
my $PROGRAM = new(__PACKAGE__);
my ($exitval,$r) =  $PROGRAM->execute(@ARGV);
exit $exitval;

__END__

=pod

=head1  NAME

MyPlace::Program::SimpleQuery

=head1  SYNOPSIS

MyPlace::Program::SimpleQuery [options] ...

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

    2014-11-22 02:51  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl


