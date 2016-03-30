#!/usr/bin/perl -w
package MyPlace::Program::Download;
use strict;
use warnings;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw();
    @EXPORT_OK      = qw();
}
use Cwd;
use MyPlace::Script::Message;
use Getopt::Long qw/GetOptionsFromArray/;
use Pod::Usage;
use MyPlace::Filename qw/get_uniqname/;
use URI;

my @OPTIONS = qw/
		help|h
		manual|man
		verbose|v
		url|u=s
		saveas|output|o|s=s
		directory|d
		name|n=s
		cookie|b:s
		log|l
		refurl|r=s
		autoname|a
		program|p=s
		maxtime|m=i
		force|f
		connect-timeout=i
		maxtry|mt=i
		quiet
		test
		compressed
		mirror|or=s@
		post=s
	/;
my $proxy = '127.0.0.1:9050';
my $blocked_host = '\n';#wretch\.cc|facebook\.com|fbcdn\.net';
my $BLOCKED_EXP = qr/^[^\/]+:\/\/[^\/]*(?:$blocked_host)(?:\/?|\/.*)$/;
my @WGET = qw{
    wget --connect-timeout 15 -q --progress bar
};
my @CURL = qw{
        curl
		--fail --globoff --location
		--progress-bar --create-dirs
		--connect-timeout 15
		--location
};
#my $UA = 'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)';
my $UA = 'Mozilla/5.0 (Windows NT 6.1; rv:38.0) Gecko/20100101 Firefox/38.0';
#'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.3) Gecko/2008092416 Firefox/3.0.3 Firefox/3.0.1';
push @WGET,'--user-agent',$UA;
push @CURL,'--user-agent', $UA;

sub new {
	my $class = shift;
	my $self = bless {},$class;
	if(@_) {
		$self->set(@_);
	}
	return $self;
}

sub set_reportor {
	my $self = shift;
	if(@_) {
		$self->{reportor} = shift;
		$self->{reportor_data} = shift;
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
	$self->{options} = cathash($self->{options},\%OPT);
	push @{$self->{urls}},@_ if(@_);
}

sub log($$) {
    my $text=shift;
    my $fn=shift;
    open FO,">>",$fn or return;
    print FO $text;
    close FO;
}

sub build_cmdline {
    my($name,$url,$saveas,%OPTS) = @_;
	#my($name,$url,$saveas,$refer,$cookie,$quiet,$maxtime) = @_;
    return undef unless($url);
    my @result;
    if($name =~ /^wget$/i) {
        push @result,@WGET;
        push @result,"--referer",$OPTS{referer} || $url;
        push @result,"--output-document",$saveas if($saveas);
		if($OPTS{cookie}) {
			push @result,"--save-cookie",$OPTS{cookie};
			push @result,"--load-cookie",$OPTS{cookie} if(-f $OPTS{cookie});
		}	
        push @result,'--read-timeout',$OPTS{maxtime} if($OPTS{maxtime});
        push @result,$url;
    }
    else {
        push @result,@CURL;
        push @result,"--url",$url;
        push @result,"--referer",$OPTS{referer} || $url;
        push @result,"--output",$saveas if($saveas);
		push @result,"-d",$OPTS{post} if($OPTS{post});
		if($OPTS{cookie}) {
	        push @result,"--cookie",$OPTS{cookie} if(-f $OPTS{cookie});
		    push @result,"--cookie-jar",$OPTS{cookie};
		}
        push @result,"--max-time",$OPTS{maxtime} if($OPTS{maxtime});
		push @result,"--silent" if($OPTS{quiet});
		push @result,"--compressed" unless($OPTS{'no-compressed'});
        if($url =~ $BLOCKED_EXP) {
            app_message "USE PROXY $proxy\n";
            push @result,"--socks5-hostname",$proxy;
        }
    }
    return @result;
}

sub _process {
    my $taskname=shift;
    my $cmdline=shift;
    my $retry = shift(@_) || 0;
    my $r=0;
#	print STDERR join(" ",@{$cmdline}),"\n";
    while($retry) {
        $retry--;
		my @data;
		if(open FI,'-|:raw',@{$cmdline}) {
		#	return undef,"$!";
			@data = <FI>;
			close FI;
		}
		$r = $?;
#        $r=system(@{$cmdline});
        return (0,@data) if($r==0);
        return 2,$! if($r==2); #/KILL,TERM,USERINT;
        $r = $r>>8;
        #2 =>
        #22 => Request Error 404,403,400
        #56 => Recv failure: Connection reset by peer
		#47 => Reach max redirects.
		#52 => curl: (52) Empty reply from server
        return $r,$! if(
			$r == 2 
		   #or $r == 22 
		   #or $r == 56 
			or $r == 6 
			or $r == 47
		#	or $r == 52
			);
		last unless($retry);
        app_warning "\rdownload:error($r), wait 2 second,retry($retry):\n$taskname\n";
        sleep 2;
    }
    return 1,'Failed retrying downloads';
}

sub fixlength_msg {
		my $a = shift;
		my $max = shift;
		my $l = length($a);
		if($l > $max) {
			my $left = int(($max)/2*3);
			my $right = $l - int($max/3)-6;
			return substr($a,0,$left) . " ... " . substr($a,$right);
		}
		else {
			return $a;
		}
}

sub execute {
	goto &download;
#	my $self = shift;
#	my $OPT;
#	if(@_) {
#		$OPT= {};
#		GetOptionsFromArray(\@_,$OPT,@OPTIONS);
#		$OPT = cathash($self->{options},$OPT);
#		push @{$self->{urls}},@_ if(@_);
#	}
#	else {
#		$OPT = $self->{options};
#	}
#	if($OPT->{help}) {
#		pod2usage('-exitval'=>1,'-verbose'=>1);
#
#		#USAGE;
#		return 3;
#	}
#	elsif($OPT->{manual}) {
#		pod2usage('--exitval'=>1,'-verbose'=>2);
#		#USAGE
#		return 3;
#	}
#	my $exitval = $self->_download($OPT);
#	return $exitval;
}


#ReEnterable Entry

sub download {
	my $self = shift;
	my $OPT;
	if(@_) {
		$OPT= {};
		GetOptionsFromArray(\@_,$OPT,@OPTIONS);
		$OPT = cathash($self->{options},$OPT);
	}
	else {
		$OPT = $self->{options};
	}
	if($OPT->{help}) {
		pod2usage('-exitval'=>1,'-verbose'=>1);

		#USAGE;
		return 3;
	}
	elsif($OPT->{manual}) {
		pod2usage('--exitval'=>1,'-verbose'=>2);
		#USAGE
		return 3;
	}
	my $exitval;
	
	my @urls;
	push @urls, @{$self->{urls}} if($self->{urls});
	push @urls,$OPT->{url} if($OPT->{url});
	push @urls,@_;
	$self->{urls} = [];
	delete $OPT->{url};

	my $count = @urls;
	
	if(!$count) {
		app_error("No URL specified\n");
		return 11;
	}
	elsif($count > 1) {
		########### Multi-URLs download mode
		delete $OPT->{saveas};
		$self->{urls} = [@urls];
		$exitval = $self->_download($OPT);
		$self->{urls} = [];
		return $self->_download($OPT);
	}
	
		########### Single URL download mode

	my @mirrors;
	my $url = $urls[0];
	my $saveas = $OPT->{saveas};
	push @mirrors,[$url,$saveas];
	push @mirrors,@{$OPT->{mirror}} if($OPT->{mirror});

	my $idx = 0;
	foreach my $up(@mirrors) {
		if(ref $up) {
			$self->{urls} = [$up->[0]];
			$OPT->{saveas} = $up->[1] || "";
		}
		else {
			$self->{urls} = [$up];
			$OPT->{saveas} = "";
		}
		app_message "Try mirror [$idx]: " . $self->{urls}[0] . " ...\n" if($idx);
		$exitval = $self->_download($OPT);
		last if($exitval == 0); #OK
		last if($exitval == 12); #File exists
		last if($exitval == 2); #Killed
		$idx++;
	}
	foreach my $key (qw/url saveas mirror/) {
		delete $self->{options}->{$key};
		delete $OPT->{$key};
	}	
	$self->{urls} = [];
	return $exitval;

}
#my $OptFlag='m:lvu:s:dn:r:b:ap:f';
#my %OPT;
#getopts($OptFlag,\%OPT);


my $STATIC_NAME_IDX = 0;
sub _get_url {
	my $self = shift;
	my $options = shift;
	my $url = shift;
	my $saveas = shift;
		if(ref $_) {
			$url = $_->[0];
			$saveas = $_->[1] if($_->[1]);
		}
		if ($url !~ m/^\w+:\/\// ) {
		    app_error("Invaild URL:\"",$url,"\"\n");
			return 11,$url,$saveas;
		}
		if($url =~ m/^([^\t]+)(?:\t+|    )(.+)$/) {
			$url = $1;
			$saveas = $2 if($2);
		}
		
		if($options->{createdir} && !$saveas) {
		    my $filename=$url;
		    $filename =~ s/^\w+:\/+[^\/]*\/+//;
		    $filename =~ s/^[^\?]*\?[^\/]*\/+//g;
		    $saveas=$filename;
		}
		if(!$saveas) {
		    my $basename=$url;
		    $basename =~ s/^.*\///;
			$basename =~ s/[\?\#].*//;
		    $basename = "index.html" unless($basename);
		    $saveas=$basename;
		}
		if($saveas =~ m/\/$/) {
		    $saveas .= "index.html";
		}
		if($saveas and $options->{autoname} and -f $saveas) {
		    $saveas = get_uniqname($saveas);
		}
		if($saveas eq ':DOWNLOADER_AUTONAME') {
			my $dlen = 5;
			my $ext = $url;
			$ext =~ s/\?[^\?]+$//;
			$ext =~ s/#[^#]+$//;
			$ext =~ s/^.*\.//;
			$ext = "" unless($ext);
			my $fn;
			do {
				$STATIC_NAME_IDX++;
				$fn = '0'x(5 - length($STATIC_NAME_IDX)) . $STATIC_NAME_IDX . ".$ext";
			} while(-f $fn);
			$saveas = $fn;
		}
		
		if ((!$options->{force}) and -f "$saveas" ) {
		    return 12,$url,$saveas;
		}
		return 0,$url,$saveas;
}

sub _download {
	my $self = shift;
	my $options = shift;
#	my $options = $self->{options} || {};
	my $downloader = $options->{program} || 'curl';
	my $cookie= $options->{cookie} || '';
	my $FAILLOG="download.failed";
	my $DOWNLOADLOG="download.log";
	
	push @{$self->{urls}},$options->{url} if($options->{url});
	#use Data::Dumper;print Data::Dumper->Dump([$self->{urls},$options->{url}],[qw/*urls *url/]);
	#die();
	if(!$self->{urls}) {
		app_error("No URL specified\n");
		return 11;
	}
	my $idx = 0;
	my $count = scalar(@{$self->{urls}});
	my $exitval = 0;
	while(@{$self->{urls}}) {
		$_ = shift @{$self->{urls}};
		next unless($_);
		my $url = $_;
		my $saveas = $options->{saveas};
		($exitval,$url,$saveas) = $self->_get_url($options,$url,$saveas);
		my $refer=$options->{refurl} || $url;
		my $name= $options->{"name"} || "";
		$idx++;
		$name = "${name}[$idx/$count]" if($count>1);
		my $message;
		if($options->{verbose}) {
		    $message = sprintf("%s\n%-8s: %s\n%-8s: %s\n%-8s: %s\n",
		            $name ? "\n$name" : "",
		            "URL",$url,
		            "SaveAs",$saveas,
		            "Refer",$refer);
		}
		else {
		    $message = "\n\t$saveas\n$name$url\n";
		}
		print STDERR $message unless($options->{quiet});
		if($exitval) {
			if($exitval == 12) {
				print STDERR "Ignored, File exists: $saveas\n";
				next;
			}
			else {
				print STDERR "Failed, Invalid URL:$url\n";
				next;
			}
		}
		my $eurl = URI->new($url);

		
		if($cookie) {
		    if(!-f $cookie) {
		        app_message "Creating cookie for $url...\n" unless($options->{quiet});
		        my @match = $url =~ /^(http:\/\/[^\/]+)\//;
		        if(@match) {
		            my $domain=$match[0];
		            system("curl --url '$domain' -c '$cookie' -o '/dev/null'");
		        }
		    }
		}
		
		#my $saveas_temp = "$saveas.downloading";
		my @cmdline = build_cmdline(
			$downloader,
			$eurl,
			undef,
			(
				post=>$options->{post},
				referer=>$refer,
				cookie=>$cookie,
				quiet=>$options->{quiet},
				maxtime=>$options->{maxtime},
				compressed=>$options->{compressed},
			)
		);
		my $maxtry = $options->{maxtry};
		if(!$maxtry) {
			if($url =~ m/(?:weipai\.cn|oldvideo\.qiniudn\.com|vlook\.cn)/) {
				$maxtry = 4; #10
			}
			else {
				$maxtry = 2;
			}
		}
		my ($r,@data)=_process("$name$url",\@cmdline,$maxtry);
		if(defined $self->{reportor}) {
			$self->{reportor}->($self->{reportor_data},$url,$r);
		}
#		print STDERR "EXITVAL:$r\n";
		if(!defined $r) {
			app_error("\nExecuting \'" . join(" ",@cmdline) . "\'\nError: ",@data,"\n");
			$exitval = 13;
			next;
		}
		elsif($r==0 and @data) {
			next if($options->{test});
			if(open FO, ">:raw",$saveas) {
				print FO @data;
				close FO;
			}
			else {
				app_error("Error writting $saveas: $!\n");
				$exitval = 4;
				next;
			}
#		    unlink ($saveas) if(-f $saveas);
#		    rename($saveas_temp,$saveas) or die("$!\n");
		    &log("$url->$saveas\n","$DOWNLOADLOG") if($options->{log});
		    app_ok "$name$saveas\t[Completed]\n" unless($options->{quiet});
			$exitval = 0;
			next;
		}
		elsif($r==2) {
#		    unlink $saveas_temp if(-f $saveas_temp);
		    app_warning "$name$url\t[Killed]\n" unless($options->{quiet});
			$exitval = 2;
			#KILLED
			return $exitval;
		}
		else {
#		    unlink $saveas_temp if(-f $saveas_temp);
		    app_error "$name$url\t[Failed]\n" unless($options->{quiet});
		    &log("$url->$saveas\n","$FAILLOG") if($options->{log});

			#FAILED
			$exitval = 1;
			next;
		}
	}
	return $exitval;
}

return 1 if caller;
my $PROGRAM = MyPlace::Program::Download->new();
exit $PROGRAM->execute(@ARGV);



__END__

=pod

=head1 NAME

download - customized frontend for wget/curl

=head1 SYNOPSIS

download [OPTIONS] URL

	download "http://www.google.com"
	download -s google.html "http://www.google.com"
	download -a "http://www.google.com"

=head1 OPTIONS

=over

=item B<--verbose>,B<-v>

Verbose messaging

=item B<--url>,B<-u>

Specify the URL

=item B<--saveas>,B<-s>

Specify target filename

=item B<--directory>,B<-d>

Create directories if necessary

=item B<--name>,B<-n>

Name downloading session

=item B<--refurl>,B<-r>

Set referer URL

=item B<--cookie>,B<-b>

Set cookie file

=item B<--log>,B<-l>

Enable logging

=item B<--autoname>,B<-a>

Auto rename if target exists

=item B<--program>,B<-p>

Specify downloader, either wget or curl

=item B<--maxtime>,B<-m>

Set timeout

=item B<--force>,B<-f>

Force overwritting

=back

=head1 DESCRIPTION

Not a downloader indeed, but simply a frontend for
some real downloader e.g. B<curl> or B<wget>.

=head1 CHANGELOG

2007-10-28	xiaoranzzz	<xiaoranzzz@myplace.hell>

* Initial version

2012-12-19	xiaoranzzz	<xiaoranzzz@myplace.hell>

* Add pod document
* Use Getopt::Long.

=head1 AUTHOR

xiaoranzzz <xiaoranzzz@myplace.hell>

=cut




# vim:filetype=perl
