#!/usr/bin/perl -w
package MyPlace::Tasks::Worker::URLRule;
use strict;
use warnings;
use parent 'MyPlace::Tasks::Worker';
use MyPlace::Weipai;
use MyPlace::Tasks::Task qw/$TASK_STATUS/;
use MyPlace::Script::Message;
use MyPlace::URLRule::SimpleQuery qw/usq_test_key usq_locate_db/;
use MyPlace::Program::SimpleQuery qw/validate_item/;
use MyPlace::URLRule::Utils qw/get_url/;
use File::Spec::Functions qw/catfile catdir/;
use MyPlace::Program qw/EXIT_CODE/;
my %USQ_HOSTS = usq_locate_db('*');
my $USQ;
#	sub set_workdir {
#		my $wd = shift;
#		return 1 unless($wd);
#		if(! -d $wd) {
#			mkdir $wd or return undef,"Error creating directory $wd:$!";
#		}
#		chdir $wd or return undef,"Error change working directory $wd:$!";
#		return 1;
#	}

	sub NEW_TASK  {
		my $task = shift;
		my $newtask = new MyPlace::Tasks::Task(@_);
		foreach(qw/target_dir source_dir workdir options level/) {
			$newtask->{$_} = $task->{$_};
		}	
		return $newtask;
	}

	sub IN_FILE {
		my $self = shift;
		my $key = shift;
		my $filename = shift;
		my $c_key = 'CACHE_IN_FILE:' . $filename;
		my $record = $self->{$c_key};
		if(!$record) {
			my $count = 0;
			if(open FI,'<',$filename) {
				foreach(<FI>) {
					chomp;
					next unless($_);
					$record->{$_} = 1;
				}
				close FI;
			}
			$self->{$c_key} = $record;
		}
		return 1 if(defined $record->{$key});
		#print STDERR "Writing $filename ...\n\t$key\n";
		if(open FO,">>",$filename) {
			print FO $key,"\n";
			close FO;
			#	print STDERR "\tOK.\n";
		}
		else {
			#	print STDERR "\tError: $!\n";
		}
		$record->{$key} = 1;
		return 0;
	}

	sub build_url {
		my $host = uc(shift(@_));
		my $id = shift;
		if($host eq 'WEIPAI.CN') {
			return MyPlace::Weipai::build_url('video',$id);
		}
		elsif($host eq 'VLOOK.CN') {
			return "http://www.vlook.cn/user_video_list?blog_id=$id";
		}
		else {
			return $id;
		}
	}

	sub expand_url {
		my $url = shift;
		if($url =~ m{^http://url.cn} || $url =~ m{http://[^\.]+\.l\.mob\.com}) {
			print STDERR "Retriving $url ...\n";
			if(open FI,"-|","curl","--progress","-D","/dev/stdout",$url) {
				while(<FI>) {
					chomp;
					if(m/\s*Location\s*:\s*(.+?)\s*$/) {
						my $next = $1;
						next unless($next =~ m/^http/);
						print STDERR "URL: $url \n => $next\n";
						close FI;
						return $next;
						last;
					}
				}
				close FI;
			}
			else {
				return;
			}
		}
	}
	sub extract_info_from_url {
		my $url = shift;
		my $host = shift;


#		if($url =~ m/^http:\/\/www\.weipai\.cn\/(?:user|videos|follows|fans)\/([^\/\s%&]+)/) {
#			my $uid = $1;
#			my $info = MyPlace::Weipai::get_data('user',$uid,1);
#			return $1,$info->{username},'weipai.cn';
#		}
#		elsif($url =~ m/weipai\.cn|l\.mob\.com/) {
#			my $user = MyPlace::Weipai::get_user_from_page($url);
#			if($user) {
#				return $user->{uid},$user->{username},'weipai.cn';
#			}
#			else {
#				return undef;
#			}
#		}
		if($url =~ m/weipai\.cn/) {
			use MyPlace::URLRule;
			my ($status,$result) = MyPlace::URLRule::request($url);
			if($status) {
				my $info = $result->{info};
				if($info) {
					return 
					$info->{uid} || $info->{user_id} || $info->{userid}, 
					$info->{uname} || $info->{user_name} || $info->{username},
					'weipai.cn'
					;
				}
			}
		}
		elsif($url =~ m/vlook\.cn/) {		
			my ($name,$id);
			if($url =~ m/\/qs\//) {
				$url =~ s/^(.*\/[^\/%&\?]+).+?$/$1/;
			}
			my $data = get_url($url,'-v');
			my @text = split("\n",$data);
				if(!$host) {
					$host = 'vlook.cn';
				}
			foreach(@text) {
				chomp;
				if(m/<a[^>]*href="\/mobile\/mta\/home\/qs\/([^"\/\?]+)[^"]*"[^>]*class="user"[^>]*>\s*([^<]+?)\s*<\/a/) {
					$name = $2;
					$id = $1;
					last;
				}
				elsif((!$name) and m/class="personal_head"><img[^>]+?alt="([^"]+?)"/) {
					$name = $1;
				}
				elsif((!$name) and m/<meta name="description" content="([^:"]+)/) {
					$name = $1;
				}
				elsif((!$id) and m/href="\/ta\/follow\/qs\/([^\/&?"]+)/) {
					$id = $1;
				}
				last if($name and $id);
			}
			$name =~ s/的个人视频主页.*$// if($name);
			return $id,$name,$host;
		}
		elsif($url =~ m/miaopai.com/) {
			require MyPlace::MiaoPai;
			my $info = MyPlace::MiaoPai::extract_info($url);
			return $info->{uid},$info->{uname},'miaopai.com';
		}
		elsif($url =~ m/meipai.com/) {
			require MyPlace::Meipai;
			my $info = MyPlace::Meipai::extract_info($url);
			return $info->{uid},$info->{uname},'meipai.com';
		}
	}

sub _validate_cmd {
	my $REG_CMD_DOWNLOAD = qr/^(:?SAVE|UPDATE|DOWNLOADER|DOWNLOAD|BATCHGET|SAVER)$/;
	my $OPTS = shift;
	my $CMD = shift;
	return $CMD unless($CMD =~ $REG_CMD_DOWNLOAD);
	if($OPTS->{'disable-all-download'}) {
		$CMD = 'DATABASE' unless($OPTS->{REALLYFORCE});
	}
	elsif($OPTS->{'disable-download'} || $OPTS->{'no-download'}) {
		$CMD = 'DATABASE' unless($OPTS->{FORCE});
	}
	return $CMD;
}


sub new {
	my $class = shift;
	my $self = $class->SUPER::new(name=>'urlrule',@_);
	$self->{routine} = \&work;
	return $self;
}

sub sites_save_links {
	my $self = shift;
	my $task = shift;
	my $record_file = shift;
	my @data = @_;
	my @dt;
	my $taskscount = 0;
	my $s_count = 0;
	my @urls;
	print STDERR "Skipped urls in file: $record_file\n";
	foreach(@data) {
		next if(!$_);
#				print STDERR ">$_\n";
		if($self->IN_FILE($_,$record_file)) {
#					print STDERR ">>$_\n";
			$s_count++;
			print STDERR "\t$_\n";
		}
		else {
			push @urls,$_;
		}
	}
	print STDERR "<Skipped $s_count urls total\n\n";
	if(!@urls) {
		return $TASK_STATUS->{DONOTHING},'No links found';
	}
	my $level = $task->{level};
	foreach(@urls) {
		$taskscount++;
		printf STDERR "+ [%d] sites <URL> AD,SAVEURL %s\n",$taskscount, $_;
		my $newtask = NEW_TASK($task,$task->{namespace},'sites','<URL>','AD,SAVEURL',$_);
		push @dt,$newtask;
	}
	if(defined $level) {
		$task->queue($level,\@dt,1);
	}
	else {
		$task->queue(\@dt,1);
	}
	return $TASK_STATUS->{DONOTHING},"Decompressed to $taskscount tasks";
}

sub score {
	my $self = shift;
	my $board = shift;
	my $id = shift;
	my $point = shift;
	return unless(defined $point);
	my @rows;
	if(open FI,"<",$board) {
		@rows = <FI>;
		close FI;
	}
	else {
		@rows = ();
	}
	my $score;
	my $count;
	if(!open FO,">",$board) {
		print STDERR "Error opening file \"$board\":$!\n";
		return;
	}
	while(@rows) {
		my $row = shift(@rows);
		if(defined $score) {
			print FO $row;
			next;
		}
		my ($r_id,$r_count,$r_point,@datas) = split(/\s*\t\s*/,$row);
		if(!$r_id) {
			print FO $row;
			next;
		}
		if($r_id eq $id) {
			$score = int($r_point + $point);
			$count = $r_count ? $r_count + 1 : 1;
			last;
		}
		else {
			print FO $row;
		}
	}
	if(!defined $score) {
		$score = $point;
		$count = 1;
	}
	print FO join("\t",$id,$count,$score,@_),"\n";
	print FO @rows if(@rows);
	close FO;
	print STDERR "SCORE: $id => $count/$score\n";
}

sub error {
	my $self = shift;
	my $task = shift;
	my $WD = $task->{target_dir} || $task->{workdir} || $self->{target_dir} || ".";
	my $msg = shift;
	my $NOTLOG = shift;
	if((!$NOTLOG) and open(my $FO,">>",catfile($WD,'errors.log'))) {
		print $FO $task->to_string(),"\n";
		print $FO "\t$msg\n";
		close $FO;
	}
	return $TASK_STATUS->{ERROR},$msg;
}

sub work {
	my $self = shift;
	my $task = shift;
	my $type = shift;
	if(!$type) {
		return $self->error($task,'No urlrule/type specified');
	}
	$task->{title} = "[urlrule] $type " . join(" ",@_);
	
	my %OPTS;
	my %WORKER_OPTS = ($self->{options} ? %{$self->{options}} : ());
	my %TASK_OPTS = ($task->{options} ? %{$task->{options}} : ());
	my @USQ_OPTS;
	my @USQ_ARGS;
	

	my @USQ_OPTS_GROUP1 = (qw/
		no-recursive
		no-createdir
		fullname
		no-download
		item
	/);

	my @USQ_OPTS_GROUP2 = (qw/
		include
		execlude
	/);
	foreach(@USQ_OPTS_GROUP1) {
		if(defined $WORKER_OPTS{$_}) {
			push @USQ_OPTS,'--' . $_;
		}
		if(defined $TASK_OPTS{$_}) {
			push @USQ_ARGS,'--' . $_;
		}
	}
	foreach(@USQ_OPTS_GROUP2) {
		if(defined $WORKER_OPTS{$_}) {
			push @USQ_OPTS,'--' . $_,$WORKER_OPTS{$_};
		}
		if(defined $TASK_OPTS{$_}) {
			push @USQ_ARGS,'--' . $_,$TASK_OPTS{$_};
		}
	}
	
	$type = lc($type);
	my $WD = $task->{target_dir} || $task->{workdir} || $self->{target_dir} || ".";
	if($type eq 'saveurl') {
		use MyPlace::URLRule::OO;
		my @urls;
		my @args;
		foreach(@_) {
			if(m/^http:\/\//) {
				push @urls,$_;
			}
			else {
				push @args,$_;
			}
		}
		my $level  = shift(@args) || 0;
		my $action = shift(@args) || '!DOWNLOADER';
		my $prefix = '';
		if($action =~ m/^(\!+)(.+)$/) {
			$prefix = $1;
			$action = $2;
		}
		$action = $prefix .  _validate_cmd({%{$self->{options}},%OPTS},$action);

		if(!@urls) {
			return $self->error($task,"No url specified");
		}
		my $ERROR_WD = $self->set_workdir($task,$WD);
		return $ERROR_WD if($ERROR_WD);
		my $UOO = MyPlace::URLRule::OO->new(
			'options'=>{
				'fullname'=>1,
			},
			'createdir'=>0,
			'action'=>$action,
		);
		foreach my $url(@urls) {
			$UOO->autoApply({
					count=>1,
					url=>$url,
					level=>$level,
			});
		}
		if($UOO->{DATAS_COUNT}) {
			return $TASK_STATUS->{FINISHED},"OK";
		}
		else {
			return $TASK_STATUS->{DONOTHING},"Nothing to do";
		}
	}
	elsif($type eq 'sites') {
		use MyPlace::Program::SimpleQuery;
		$USQ ||= new MyPlace::Program::SimpleQuery('--thread',1,@USQ_OPTS);

		my $hosts_o = shift;
		
		if(!$hosts_o) {
			return $self->error($task,'No hosts specified');
		}
		if(lc($hosts_o) eq 'savelinks') {
			$WD = $task->{source_dir} || $self->{source_dir} || ".";
			my $ERROR_WD = $self->set_workdir($task,$WD);
			return $ERROR_WD if($ERROR_WD);
			my $record_file = catfile('sites','savelinks.lst');
			my $url = shift;
			my $level = shift(@_) || 0;
			use MyPlace::URLRule::OO;
			my $UOO = MyPlace::URLRule::OO->new(createdir=>0);
			my ($c,@data) =$UOO->autoApply({url=>$url,level=>$level});
			return $self->sites_save_links($task,$record_file,@data);
		}
		elsif(lc($hosts_o) eq 'saveurls') {
			$WD = $task->{source_dir} || $self->{source_dir} || ".";
			my $ERROR_WD = $self->set_workdir($task,$WD);
			return $ERROR_WD if($ERROR_WD);
			my $record_file = catfile('sites','savelinks.lst');
			return $self->sites_save_urls($task,$record_file,@_);	
		}
	
		my $command = shift;
		if(!$command) {
			$task->{summary} = 'No action assicated';
			return $self->error($task,$task->{summary});
		}
		my $FROMURL = "";
		my $HOSTS_FROM_URL = "";
		my $ARG1 = shift(@_);
		if(!$ARG1) {
			return $self->error($task,'Need more arguments');
		}
		elsif($ARG1 and $ARG1 =~ m/^https?:/) {
				
				my $UURL = expand_url($ARG1);
				if($UURL) {
					app_warning("URL => $UURL\n");
					return work($self,$task,$type,$hosts_o,$command,$UURL,@_);
				}

				my ($key1,$key2,$key3) = extract_info_from_url($ARG1);
				if(!($key1 or $key2)) {
					return $self->error($task,'Extract information from URL failed');
				}
				unshift @_,($key1,$key2,$ARG1);
				$HOSTS_FROM_URL = $key3 if($key3);
				$FROMURL = join(", ",$key1 || (),$key2 || (),$key3 || ());
				app_message2 "$ARG1 =>\n";
				app_message2 "    ",$FROMURL,"\n";
				#die();
				$FROMURL = "$ARG1 => $FROMURL ";
		}
		else {
			unshift @_,$ARG1;
		}					
	
		if(!$hosts_o) {
			$hosts_o = $HOSTS_FROM_URL;
		}
		elsif("$hosts_o" eq "$HOSTS_FROM_URL") {
		}
		elsif($hosts_o ne '*') {
			$hosts_o = $hosts_o . ',' . $HOSTS_FROM_URL if($HOSTS_FROM_URL);
		}
		else {
			my $target = $_[0]; #'Never undef';
			my @qhosts;
			if($target) {
				my %dbs = %USQ_HOSTS;
				if(%dbs) {
					foreach my $dbname(keys %dbs) {
						my $dbfile = $dbs{$dbname};
						if(usq_test_key($dbfile,$target)) {
							push @qhosts,$dbname;
							if($dbname eq 'weibo.com') {
								push @qhosts,'sinacn.weibodangan.com';
							}
						}
					}
				}
				else {
					@qhosts = ('*');
				}
			}
			if(!@qhosts) {
				@qhosts = qw/
					weipai.cn
					vlook.cn
					meipai.com
					miaopai.com
					weibo.com
					moko.cc
					meitulu.com
				/;
			}
			print STDERR "HOSTS [$hosts_o] => ";
			$hosts_o = join(",",@qhosts);
			print STDERR "[$hosts_o]\n";
		}
		my ($hosts,@HOSTS_NEXT) = split(/\s*[,\|]\s*/,$hosts_o);

		if(@HOSTS_NEXT) {
			my $taskscount = 1 + scalar(@HOSTS_NEXT);
			my @dt;
			my $level = $task->{level};
			foreach($hosts,@HOSTS_NEXT) {
				printf STDERR "+ %10s %s %s\n", $_, $command,join(" ",@_);
				my $newtask = NEW_TASK($task,$task->{namespace},'sites',$_,$command,@_);
				push @dt,$newtask;
			}
			if(defined $level) {
				$task->queue($level,\@dt,1);
			}
			else {
				$task->queue(\@dt,1);
			}
			return $TASK_STATUS->{DONOTHING},"Decompressed to $taskscount tasks";
		}	

		my ($CMD,@CMDS_NEXT) = split(/\s*[,\|]\s*/,uc($command));
		
		if($CMD eq 'ADD') {
		}
		elsif($CMD =~ m/^[ADFUS]+$/) {
			my @CC;
			for(my $i=0;$i<length($CMD);$i++) {
				my $C = substr($CMD,$i,1);
				if($C eq 'A') {
					push @CC,'ADD';	
				}
				elsif($C eq 'D') {
					push @CC,'DOWNLOADER';
				}
				elsif($C eq 'F') {
					push @CC,'FOLLOW';
				}
				elsif($C eq 'U') {
					push @CC,'UPDATE';
				}
				elsif($C eq 'S') {
					push @CC,'SAVE';
				}
				elsif($C eq 'L') {
					push @CC,'L';
				}
			}
			$CMD = shift @CC;
			unshift @CMDS_NEXT,@CC;
		}

		if($CMD eq '!UPDATE') {
			$CMD = '!DOWNLOADER';
#			if(0 and lc($hosts) =~ m/weipai.cn|weibo.com|weishi.com|vlook.cn|meipai.com|miaopai.com|meitulu.com/) {
#				$CMD = '!DOWNLOADER';
#			}
#			else {
#				$CMD = 'DOWNLOADER';
#			}
		}
		elsif($CMD eq 'UPDATE') {
			$CMD = 'DOWNLOADER';
		}

		
		
		if(@CMDS_NEXT) {
			my $taskscount = 1 + scalar(@CMDS_NEXT);
			my @dt;
			my $level = $task->{level};
			foreach($CMD,@CMDS_NEXT) {
				printf STDERR "+ %s %10s %s\n",$hosts, $_, join(" ",@_);
				my $newtask = NEW_TASK($task,$task->{namespace},'sites',$hosts,$_,@_);
				push @dt,$newtask;
			}
			@CMDS_NEXT = ();
			if(defined $level) {
				$task->queue($level,\@dt,1);
			}
			else {
				$task->queue(\@dt,1);
			}
			return $TASK_STATUS->{DONOTHING},"Decompressed to $taskscount tasks";
		}	

		my $URLRULE_SITES_COMMANDS = '^(?:ADD|FOLLOW|!SAVE|SAVE|SAVEURL|UPDATE|SAVEURLS|DOWNLOADER|DATABASE|!DATABASE)$';

#		if($CMD !~ /$URLRULE_SITES_COMMANDS/) {
#			$CMD = 'SAVE';
#			unshift @_,$command;
#		}	
		
#		if(uc($hosts) eq 'FROMURLS') {
#			$CMD = 'ADD';
#			$hosts = undef;
#		}

		
		$task->{title} = "[urlrule] " . join(" ",('sites',$hosts || '<URL>',$CMD,@_));
		#Pre Process
		if(@_) {
			my $id = shift;
			my $name  = shift;
			if(!defined $name) {
				if($id =~ m/^(.+)\t+([^\t]+)$/) {
					$id = $1;
					$name = $2;
					unshift @_,$id,$name;
				}
				else {
					unshift @_,$id;
				}
			}
			else {
				unshift @_,$id,$name;
			}
			return $TASK_STATUS->{DONOTHING} unless(validate_item($id,$name));
		}
		
		if($CMD =~ m/^!!(.+)$/) {
			$OPTS{FORCE} = 1;
			$OPTS{REALLYFORCE} = 1;
			$CMD = $1;
		}
		elsif($CMD =~ m/^!(.+)$/) {
			$CMD = $1;
			$OPTS{FORCE} = 1;
		}
		elsif($CMD =~ m/^([\~\@\#\$\%\&?\+\-\*\^])(.+)$/) {
			$CMD = $2;
			$OPTS{$1} = 1;
		}

		$CMD = _validate_cmd({%{$self->{options}},%OPTS},$CMD);

		if($CMD eq 'ADD' || $CMD eq 'FOLLOW' || $CMD eq 'LIKES' || $CMD eq 'FOLLOW_LIKES') {
			$WD = $task->{source_dir} || $task->{workdir} || $self->{source_dir} || "";
		}
		my $ERROR_WD = $self->set_workdir($task,$WD);
		return $ERROR_WD if($ERROR_WD);
		
		if($CMD eq 'SAVECLIPS') {
			if(open FO,">>",'SAVECLIPS.log') {
				print FO @_,"\n";
				close FO;
			}
			$CMD = "DOWNLOADER";
		}
		if($CMD eq 'SEARCH') {
			my $id = shift;
			my $name = shift;
			my($exit,$r) = $USQ->execute(@USQ_ARGS,"--hosts",$hosts,"SEARCH",$id,$name);

		}
		elsif($CMD eq 'SAVEURLS') {
			my $id = shift;
			my $name = shift;
			my $URL = shift;
			if(!($id or $name)) {
				return $self->error($task,"Invalid URL $URL");
			}
			my $exitval;
			my $msg = "OK";
			$task->{title} = "[urlrule] sites $hosts SAVEURLS $URL " . ($id or $name); 
			push @USQ_ARGS,'--force' if($OPTS{FORCE});
			foreach($URL,@_) {
				my ($exit,$r) = $USQ->execute(@USQ_ARGS,'--hosts',$hosts,'--saveurl',$_,($id or $name));
				if($exit != 0 ) {
					$exitval = 1;
					$msg = "Error saving URL:$_\n";
				}
				elsif($r and $r->{directory}) {
					foreach(@{$r->{directory}}) {
						push @{$task->{dir_updated}},[$WD, $_];
					}
				}
			}
			if($exitval) {
				return $self->error($task,$msg);
			}
			else {
				return $TASK_STATUS->{FINISHED},$msg;
			}	
		}
		elsif($CMD eq 'SAVEURL') {	
			my $id = shift(@_) || "";
			my $name = shift(@_) || "";
			my $URL = shift;
			if(!$URL) {
				return $self->error($task,"No URL specified");
			}
			$task->{title} = "[urlrule] sites $hosts SAVEURL $URL $id $name";
			push @USQ_ARGS,'--force' if($OPTS{FORCE});
			#push @USQ_ARGS,'--force';
			#push @USQ_ARGS,'--force-action';# if($OPTS{FORCE});
			my($exitval,$r) = $USQ->execute(@USQ_ARGS,'--hosts',$hosts,'--saveurl',$URL,($id or $name));
			if($exitval == 0) {
				if($r and $r->{directory}) {
					foreach(@{$r->{directory}}) {
						push @{$task->{dir_updated}},[$WD, $_];
					}
				}
				$self->score("score_urlrule_sites.txt","$hosts/$id",1,$name);
				return $TASK_STATUS->{FINISHED},"=> $name/$hosts/$id";
			}
			elsif($exitval == 2) {
				$self->score("score_urlrule_sites.txt","$hosts/$id",0,$name);
				return $TASK_STATUS->{DONOTHING},$FROMURL . 'Nothing to do';
			}
			else {
				return $self->error($task,"Failed");
			}
		}
		elsif($CMD eq 'FOLLOW') {
			my $id = shift;
			my $name  = shift || "";
			my $URL = shift;
			my $UNAME = uc($name);
			if($UNAME =~ /$URLRULE_SITES_COMMANDS/) {
				unshift @_,$name;
				$name = "";
			}
			$task->{title} = "[urlrule] sites $hosts FOLLOW $id $name";
			my $dstd = "sites/$hosts";
			if(! -d $dstd) {
				app_warning("Creating directory [$dstd] ... ");
				if(system("mkdir","-p","--",$dstd)==0) {
					print STDERR "\t[OK]\n";
				}
				else {
					print STDERR "\t$!\t[FAILED]\n";
					return $self->error($task,"Create directory [$dstd] failed:$!");
				}
			}
			#print STDERR getcwd(),"\n";
			#print STDERR "$dstd/follows.txt";
			if(system('simple_query','-f',"$dstd/follows.txt",'--command','additem','--',$id,$name)==0) {
				$task->{git_commands}=[['add',catfile($WD,"$dstd/follows.txt")]];
				return $TASK_STATUS->{FINISHED}, ($FROMURL ? "${FROMURL}OK" : "OK");
			}
			else {
				return $TASK_STATUS->{DONOTHING},($FROMURL ? "${FROMURL}FAILED" : "FAILED");
			}
	
		}
		elsif($CMD eq 'ADD') {
			my $id = shift;
			my $name = shift;
			my $URL = shift;
			unless($id and $name) {
				return $self->error($task,'No id/name specified');
			}
			$task->{title} = "[urlrule] sites $hosts ADD $id $name";
			app_message2 "\tAdd [$id $name] to database of [$hosts]\n";
			if($USQ->execute(@USQ_ARGS,'--host',$hosts,'--command','additem','--',$id,$name)==0) {
				return $TASK_STATUS->{DONOTHING},($FROMURL ? "${FROMURL}OK" : "OK");
			}
			else {
				return $TASK_STATUS->{DONOTHING},($FROMURL ? "${FROMURL}FAILED" : "FAILED");
			}
	
		}
		elsif($CMD eq 'FOLLOW_LIKES') {
			my $id = shift;
			my $name  = shift;
			my $URL = shift(@_) if($FROMURL);
			my $begin_cursor = shift;
			my $last_cursor = shift;
			
			if($last_cursor) {
				#	%s	%s	%d	%d
			}
			elsif($begin_cursor) {
				#	%s	%s	%d
				$last_cursor = $begin_cursor;
				$begin_cursor = 0;
			}
			elsif($name) {
				if($id =~ m/^[\da-zA-Z]{24}$/) {
					#real id
				}
				elsif($name =~ m/^\d+$/) {
					#	%s %d
					$begin_cursor = 0;
					$last_cursor = $name;
					require MyPlace::Weipai;
					my $nid = MyPlace::Weipai::id($id);
					if($nid) {
						$name = $id;
						$id = $nid;
					}
				}
			}
			elsif($id) {
				require MyPlace::Weipai;
				my $nid = MyPlace::Weipai::id($id);
				if($nid) {
					$name = $id;
					$id = $nid;
				}
			}
			else {
				return $self->error($task,"Nothing to do");
			}

			if(!$name) {
			}
			elsif($name =~ m/^回复@(.+?):?\s*$/) {
				$name = $1;
			}
			elsif($id =~ m/^回复@(.+?):?\s*$/) {
				$id = $1;
			}

			my @key1 = ($id);
			push @key1,$name if(defined $name);

			my @key2 = ();
			push @key2, $begin_cursor if(defined $begin_cursor);
			push @key2, $last_cursor if(defined $last_cursor);
			$task->{title} = "[urlrule] sites $hosts FOLLOW_LIKES " . join(" ",@key1);
			my $dstd = "sites/$hosts";
			
			my @cmds = ();
			if($OPTS{FORCE}) {
				push @cmds , '!LIKES','!';
			}
			else {
				push @cmds, 'LIKES';
			}
			my $newtask = NEW_TASK($task,$task->{namespace},'sites',$hosts,@cmds,@key1,@key2,@_);

			$task->queue($task->{level},$newtask,1);
			if(! -d $dstd) {
				app_warning("Creating directory [$dstd] ... ");
				if(system("mkdir","-p","--",$dstd)==0) {
					print STDERR "\t[OK]\n";
				}
				else {
					print STDERR "\t$!\t[FAILED]\n";
					return $self->error($task,"Create directory [$dstd] failed:$!");
				}
			}
			#print STDERR getcwd(),"\n";
			#print STDERR "$dstd/follow_likes.txt";
			if(system('simple_query','-f',"$dstd/follow_likes.txt",'--command','additem','--',@key1)==0) {
				$task->{git_commands}=[['add',catfile($WD,"$dstd/follow_likes.txt")]];
				return $TASK_STATUS->{FINISHED}, ($FROMURL ? "${FROMURL}OK" : "OK");
			}
			else {
				return $TASK_STATUS->{DONOTHING},($FROMURL ? "${FROMURL}FAILED" : "FAILED");
			}
	
		}
		elsif($CMD eq 'LIKES') {
			if($hosts ne 'weipai.cn') {
				return $self->error($task,"Command $CMD not support for host $hosts");
			}

			my $id = shift;
			if(!$id) {
				return $self->error($task,"No ID specified");
			}
			my $FOLLOW_ID = 0;
			if($id eq '!') {
				$FOLLOW_ID = 1;
				$id = shift;
			}
			if(!$id) {
				return $self->error($task,"No ID specified");
			}
			my $HDIR = catdir('sites',$hosts);
			my $FDIR = catdir($HDIR,'likes');
			foreach($HDIR,$FDIR) {
				next if(-d $_);
				if(!mkdir $_) {
					return $self->error($task,"Creating directory $_:$!");
				}
			}
			my $FALL = catfile($HDIR,'likes_all.txt');
			my $A = $self->{URLRULE_LIKES_ALL};
			my $A_count;
			if(!$A) {
				$A = {};
				if(open FI,'<',$FALL) {
					while(<FI>) {
						chomp;
						if(m/^([^\t]+)\t(.*)$/) {
							$A->{$1} = $2;
							$A_count++;
						}
						elsif(m/^([^\t]+)/) {
							$A->{$1} = $1;
							$A_count++;
						}
					}
					close FI;
				}
				app_message "Read $A_count items from $FALL\n";
			}
			open my $FO_ALL,">>",$FALL or print STDERR "Error opening $FALL:$!\n";	
			use MyPlace::Weipai qw/get_likes/;
			my @result;
			my $name;
			if($id !~ m/^[45][0-9a-zA-Z]{23}$/) {
				require MyPlace::Weipai;
				my $nid = MyPlace::Weipai::id($id);
				if($nid) {
					$name = $id;
					$id = $nid;
				}
			}
			else {
				$name = shift;
			}
			my @IDs = ($id);
			my $key = ($id && $name) ? "$id $name" : $id ? $id : $name ? $name : '';
			my $URL = shift(@_) if($FROMURL);
			my $cursor = shift;
			my $LAST_CURSOR = shift;
			my $count = 0;
			foreach my $id (@IDs) {
				if($id =~ m/^\s*([^\s]+)\s*\t\s*([^\s]+)/) {
					$id = $1;
					$name = $2;
				}
				else {
					$id =~ s/^\s+//;
					$id =~ s/\s+.*//;
					$name ||= $id;
				}
				my $fname = 'likes_' . $name . '.txt';
				$fname =~ s/[\/\\\?\*:>]+/./;
				my $FLIKE = catfile($FDIR,$fname);
				my %record;
				if(open FI,'<',$FLIKE) {
					while(<FI>) {
						chomp;
						if(m/^([^\t]+)/) {
							$record{$1} = 1;
							if(!$A->{$1}) {
								$A->{$1} = 1;
								print $FO_ALL $_,"\n" if($FO_ALL);
							}
						}
					}
					close FI;
				}
				my $likes = $cursor ? get_likes($id,10,$cursor) : get_likes($id,10);#->{video_list};
				if(!open FO,'>>',$FLIKE) {
					print STDERR "Error opening $FLIKE: $!\n";
					next;
				}
				while(1) {
					my $processed = 1;
					if($likes->{video_list}) {
						print STDERR " \t=> " . scalar(@{$likes->{video_list}}) . " liked video items\n";
					}
					foreach(@{$likes->{video_list}}) {
						next unless(ref $_);
						foreach my $key(qw/video_desc nickname video_id video_desc user_id video_play_url date/) {
							$_->{$key} = '' unless(defined $_->{$key});
						}
						$_->{video_desc} =~ s/[\r\n]+//g;
						$_->{video_desc} =~ s/\s{2,}/ /g;
						if($_->{video_play_url} =~ m/\/(\d+)\/(\d+)\/(\d+)\//) {
							$_->{date} = "$1$2$3";
						}
						my $k = join("\t",
							$_->{video_id} ,
							$_->{date} ,
							$_->{user_id} ,
							$_->{nickname} ,
							$_->{video_play_url} ,
							$_->{video_desc}
						);

						if($record{$_->{video_id}}) {
							next;# unless($OPTS{FORCE});
						}
						else {
							$record{$_->{video_id}} = 1;
							print FO $k,"\n";
						}
						$processed = 0;	

						if($A->{$_->{video_id}}) {
							next unless($OPTS{FORCE});
						}
						else {
							$A->{$_->{video_id}} = 1;
							print $FO_ALL $k,"\n" if($FO_ALL);
						}
						push @result,"http://www.weipai.cn/video/$_->{video_id}";
						print STDERR "LIKES: $_->{date} $_->{video_id}\t$_->{nickname}\t$_->{video_desc}\n";
						$count++;
					}
					if($LAST_CURSOR and $cursor < $LAST_CURSOR) {
						$cursor = $cursor + 10;
					}
					elsif($processed) {
						last;
					}
					elsif($likes->{next_cursor}) {
						$cursor = $likes->{next_cursor};
					}
					else {
						last;
					};
					$likes = get_likes($id,10,$cursor);#->{video_list};
				}
				close FO;
				print STDERR "LIKES: Get $count item(s) from <$name>\n";
				if($count > 0) {
					$self->score(catfile($HDIR,'LIKES_SCORE.txt'),"$id",1,$name,$cursor || ());
				}
				else {
					$self->score(catfile($HDIR,'LIKES_SCORE.txt'),"$id",0,$name,$cursor || ());
				}
			}
			$self->{URLRULE_LIKES_ALL} = $A;
			my $URL_CMD = ($FOLLOW_ID ? 'AFD' : 'AD') . ',' . ($OPTS{FORCE} ? '!!SAVEURL' : 'SAVEURL');
			if(@result) {
				my @dt;
				foreach(@result) {
					printf STDERR "+ %s $URL_CMD %s\n",$hosts, $_;
					my $newtask = NEW_TASK($task,$task->{namespace},'sites',$hosts,$URL_CMD,$_);
					push @dt,$newtask;
				}
				my $level = 20;
				if($level) {
					$task->queue($level,\@dt,1);
				}	
				else {
					$task->queue(\@dt,1);
				}
			}
			if($count > 0) {
				return $TASK_STATUS->{FINISHED},"Get $count items\n";
			}
			else {
				return $TASK_STATUS->{DONOTHING};
			}
		}
		else{
			#(($CMD eq '!SAVE') || ($CMD eq 'SAVE') || ($CMD eq 'UPDATE')) {
			my $key = shift;
			my $info = shift(@_) || "";
			if($key and $key =~ m/^\s*(.+)[\t>](.+?)\s*$/) {
				$key = $1;
				unshift @_,$info;
				$info = $2;
			}
			$task->{title} = "[urlrule] sites $hosts $CMD $key $info";
			my $S_BOARD = 'score_urlrule_sites.txt';
			my @prog = (@USQ_ARGS,"--hosts",$hosts,'--command',$CMD);
			push @prog,'--force' if($OPTS{FORCE});
			if($key) {
				push @prog,'--',$key;
			}
			elsif($info) {
				push @prog,'--',$info;
			}
			my ($r,$result) = $USQ->execute(@prog);
			if($r == 0) {
				if($result and $result->{directory}) {
					foreach(@{$result->{directory}}) {
						push @{$task->{dir_updated}},[$WD, $_];
					}
				}
				$self->score($S_BOARD,"$hosts/$key",1,$info);
				return $TASK_STATUS->{FINISHED},$FROMURL . 'OK';
			}
			if($r == 2) {
				$self->score($S_BOARD,"$hosts/$key",0,$info);
				return $TASK_STATUS->{DONOTHING},$FROMURL . 'Nothing to do';
			}
			elsif($r == 3) {
				if($result and $result->{directory}) {
					foreach(@{$result->{directory}}) {
						push @{$task->{dir_updated}},[$WD, $_];
					}
				}
				return $self->error($task,$FROMURL . 'Error');
			}
			else {
				return $self->error($task,$FROMURL . "Program aborted");
			}
		}
		#else {
		#	return $self->error($task,"Invalid command [$CMD]\n");
		#}
	}
	elsif($type eq 'task') {
		my $ERROR_WD = $self->set_workdir($task,$self->{target_dir});
		return $ERROR_WD if($ERROR_WD);
		my $action = shift;
		my @queries = @_;
		
		if(!$action) {
			return $self->error($task,'No action specified');
		}
	
		if(!@queries) {
			$task->{summary} = 'No query specified';
			return $self->error($task,$task->{summary});
		}
	
		my $URLRULE_TASK_ACTIONS = '^(?:UPDATE|DOWNLOAD|ECHO|DUMP)$';
		my $CMD = uc($action);

		if($CMD !~ /$URLRULE_TASK_ACTIONS/) {
			return $self->error($task,"[urlrule task] Invalid action $action");
		}

		$task->{title} = "[urlrule task] $action " . join(" ",@queries);
		my @prog = qw/urlrule_task/;
		if($CMD eq 'DOWNLOAD') {
			push @prog,qw/--action DOWNLOAD --no-urlhist/;
		}
		elsif($CMD eq 'UPDATE') {
			push @prog,qw/--action DOWNLOAD/;
		}
		else {
			push @prog,"--action",$CMD;
		}
		push @prog,@queries;
		print STDERR "-- ",join(" ",@prog),"\n";
		if(system(@prog,@queries) == 0 ) {
			return $TASK_STATUS->{FINISHED},"OK";
		}
		else {
			return $TASK_STATUS->{FINISHED},"FAILED";
		}
	}
	elsif($type eq 'action') {
		my $ERROR_WD = $self->set_workdir($task,$self->{target_dir});
		return $ERROR_WD if($ERROR_WD);
		my $url = shift;
		my $level = shift(@_) || 0;
		my $action = shift(@_) || 'SAVE';
		my $prefix = '';
		if($action =~ m/^(\!+)(.+)$/) {
			$prefix = $1;
			$action = $2;
		}
		$action = $prefix .  _validate_cmd({%{$self->{options}},%OPTS},$action);
		$task->{title} = "[urlrule action] $url $level $action";
		use MyPlace::URLRule::OO;
		my $URLRULE = new MyPlace::URLRule::OO('action'=>$action,'thread'=>1);
		$URLRULE->autoApply({
				count=>1,
				url=>$url,
				level=>$level,
		});
		if($URLRULE->{DATAS_COUNT}) {
			return $TASK_STATUS->{FINISHED},"OK";
		}
		else {
			return $TASK_STATUS->{DONOTHING},"Nothing to do";
		}
	}
	else {
		my $ERROR_WD = $self->set_workdir($task,$self->{source_dir});
		return $ERROR_WD if($ERROR_WD);
		$task->{title} = join(" ",'urlrule',$type,@_);
		my $r = system('urlrule',$type,@_);
		if($r == 0) {
			return $TASK_STATUS->{FINISHED},"OK";
		}
		elsif($r == 2) {
			return $TASK_STATUS->{DONOTHING},'Killed';
		}
		$r = $r>>8;
		if($r == $self->EXIT_CODE('IGNORED')) {
			return $TASK_STATUS->{DONOTHING},'Nothing to do';
		}
		else {
			return $self->error($task,'Error');
		}
	}
}

sub execute_task {
	my $self = shift;
	my $task = shift;
	chdir $self->{KEPTWD} if($self->{KEPTWD});
	app_message " * " . ($task->{title} || $task->to_string()) . "\n";
	my ($r,$s) = $self->process($task,$task->content());
	if($task->{summary}) {
		print STDERR $task->{summary},"\n";
	}
	my @NEWTASKS;
	if($r == $TASK_STATUS->{NEWTASKS}) {
		@NEWTASKS = @{$s} if($s);
	}
	if($task->tasks) {
		push @NEWTASKS,$task->tasks;
	}
	if(@NEWTASKS) {
		foreach my $ts (@NEWTASKS) {
			my $level = shift(@$ts);
			next if(!defined $level);
			if($level =~ m/^\s*(\d+)\s*$/) {
			$level = $1;
			}
			else {
				unshift @$ts,$level;
				$level = undef;
			}
			my $tss = $ts->[0];
			if(!$tss) {
			}
			elsif(ref $tss eq 'ARRAY') {
				foreach(@$tss) {
					($r,$s) = $self->execute_task($_) if($_);
				}
			}
			else {
				($r,$s) = $self->execute_task($tss)
			}
		}
	}
	return $r;
}

sub execute {
	my $self = shift;
	my $OPTS = shift;
	my $task = MyPlace::Tasks::Task->new('urlrule',@_);
	$task->{options} = $OPTS;
	use Cwd qw/getcwd/;
	$self->{KEPTWD} = getcwd;
	return $self->execute_task($task);
}

1;

package MyPlace::Tasks::Worker::URLRule::Program;
use parent 'MyPlace::Program';
our $VERSION = "1.0";
sub OPTIONS {qw/
	help|h
	directory|d=s
	no-createdir|nc
	no-recursive|nr
	no-download|nd
	disable-download|dd
	disable-all-download|dad
	fullname
	include|I:s
	exclude|X:s
/;}
sub USAGE {
	my $appname = $0;
	$appname =~ s/^.*[\/\\]//;
	print STDERR "$appname v$VERSION - URLRule worker\n\n";
	print STDERR "Usage: $appname [--directory <path>] ...\n\n";
	print STDERR "\t$appname sites weipai.cn DOWNLOADER Amanda5275\n";
	print STDERR "\t$appname action http://www.moko.cc/post/12344.html 0 SAVE\n\n";
	print STDERR "Copyright, 2015-, Eotect\n";
	return 0;
}
sub MAIN {
	my $self = shift;
	my $OPTS = shift;
	my $APP = new MyPlace::Tasks::Worker::URLRule;
	$self->{options} = {%$OPTS};
	$APP->{options} = {%$OPTS};
	$APP->{source_dir} = "urlrule";
	if($OPTS->{directory}) {
		$APP->{target_dir} = $OPTS->{directory};
	}
	exit $APP->execute($OPTS,@_);
}
return 1 if(caller);
my $APP = new MyPlace::Tasks::Worker::URLRule::Program;
exit $APP->execute(@ARGV);


