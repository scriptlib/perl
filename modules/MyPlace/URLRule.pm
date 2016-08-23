#!/usr/bin/perl -w
package MyPlace::URLRule::Request;
sub new {
	my $class = shift;
	return bless {url=>'',level=>'',action=>''},$class;
}
1;

package MyPlace::URLRule;
use URI;
use URI::Escape;
use MyPlace::Script::Message;
use MyPlace::URLRule::Utils qw/&get_url &parse_pages/;
use Cwd qw/abs_path getcwd/;
use strict;

BEGIN {
    use Exporter ();
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
	$VERSION	= 'v2.0';
    @ISA        = qw(Exporter);
	@EXPORT		=	qw/&parse_rule &apply_rule &set_callback get_rule_handler/;
    @EXPORT_OK  = qw/
			@URLRULE_LIB
			$URLRULE_DIRECTORY
			urlrule_quick_parse
			parse_rule
			apply_rule
			get_domain
			get_rule_dir
			set_callback
			get_rule_handler
			locate_file
			get_rule
			get_handler
			request
	/;
}

#my $URLRULE_DIRECTORY = "$ENV{XR_PERL_SOURCE_DIR}/urlrule";

our $USER_URLRULE_DIRECTORY = "$ENV{HOME}/.urlrule";
our $URLRULE_DIRECTORY = "$ENV{XR_PERL_SOURCE_DIR}/urlrule";
our @URLRULE_LIB = (getcwd . "/urlrule",$USER_URLRULE_DIRECTORY,$URLRULE_DIRECTORY);

our $Config;
#unshift @INC,@URLRULE_LIB;
foreach(@URLRULE_LIB) {
	if(-f "$_/config.pm") {
		#print STDERR "Loading $_/config.pm\n";
		require "$_/config.pm";
	}
}
$Config ||= {'maps.domain'=>{}};
#use Data::Dumper;die Data::Dumper->Dump([$Config],['*Config']),"\n";

my %CALLBACK;

sub get_rule_dir() {
    return $URLRULE_DIRECTORY;
}
sub get_domain($) {
    my $url = shift;
	$url =~ s/^.*?:\/+//g;
	$url =~ s/\/.*//g;
	$url =~ s/:\d+$//;
	return $url;
    if($url =~ /([^\.\/]+\.[^\.\/]+)\//) {
        return $1;
    }
    elsif($url =~ /^([^\.\/]+\.[^\.\/]+)$/) {
        return $1;
    }
    else {
        return $url;
    }
}

use File::Spec;
sub locate_file {
	my $name = shift;
	my $filepath = $name;
	foreach my $dir(@URLRULE_LIB) {
		my $path = File::Spec->catfile($dir,$name);
		if(-f $path || -d $path) {
			$filepath = $path;
			last;
		}
	}
	return $filepath;
}

sub locate_source {
	my $domain = shift;
	my $level = shift;
	my $source = undef;
    do 
    {
        foreach my $directory (
			map {("$_/$level","$_/common")} @URLRULE_LIB
		){
            next unless(-d $directory);
            for my $basename 
                    (
                        $domain,
                        "${domain}.pl",
                        "www.$domain",
                        "www.${domain}.pl",
                    )

            {
                if(-f "$directory/$basename") 
                {
                    $source = "$directory/$basename";
                    last;
                }
            }
            last if($source);
        }
    } while($domain =~ s/^[^\.]*\.// and !$source);
	return $source;
}



#parse_url
#http://www.google.com
#	-> {url=>http://www.google.com,domain=>google.com,level=>0}
#http://www.google.com 1
#	-> {url=>http://www.google.com,domain=>google.com,level=>1}
#http://www.google.com 1 download
#	-> {url=>http://www.google.com,domain=>google.com,level=>1,action=>download}
#http://www.google.com download
#	-> {url=>http://www.google.com,domain=>google.com,level=>0,action=>download}
#http://www.google.com domain:baidu.com 1
#	-> {url=>http://www.google.com,domain=>baidu.com,level=>1}
sub parse_rule {
    my %r;
    $r{url} = shift;
    $r{level} = shift;
    if($r{level} and $r{level} =~ /^domain:(.*)$/) {
        $r{domain} = $1;
        $r{level} = shift;
    }

    if($r{level}) {
		if($r{level} =~ m/^:(.+)$/) {
			$r{directory} = "$1";
			$r{level_desc} = "$1";
			$r{level} = 0;
		}
       elsif($r{level} !~ /^[+\-\d]+$/) {
        unshift @_,$r{level};
        $r{level} = 0;
       }
    }
    else {
        $r{level} = 0;
    }
	if($r{url} =~ m/^urlrule:\/\/([^\/]+)\/(\d+)\/(.+)$/) {
		$r{target}=$3;
		$r{url}=$1;
		$r{target_level}=$r{level};
		$r{level}=$2;
	}
	else {
		$r{target}=$r{url};
		$r{target_level}=$r{level};
	}
    if($r{url} =~ /^local:([^\/]+)/) {
        $r{"local"} = $1;
        $r{url} =~ s/^local:/file_/;
        if($r{url} =~ /^file_[^\/]+\/(.*)$/) {
            $r{"local_path"} = abs_path($1);
        }
    }
    if($r{url} !~ /^https?:\/\//i) {
        $r{url} = "http://" . $r{url};
    }
    $r{domain} = get_domain($r{url}) unless($r{domain});
    $r{action} = shift;
    $r{action} = "" unless($r{action});

    @{$r{args}} = @_;
    my $domain = $r{domain};
	$r{directory} = $r{level} unless($r{directory});
	$r{source} = locate_source($r{domain},$r{directory});
	if(!$r{source}) {
		my $domain = $r{domain};
		my $md;
		do {
			$md  = $Config->{'maps.domain'}->{$domain};
			$r{source} = locate_source($md,$r{directory}) if($md);
		} while($domain =~ s/^[^\.]*\.// and !$r{source});
		$r{domain} = $md if($r{source});
	}
	if(!$r{source}) {
		foreach(@URLRULE_LIB) {
			if(-d $_) {
				$r{source} = "$_/$r{directory}/$r{domain}";
				last;
			}
		}
	}
    $r{source} 
        = "urlrule/$r{directory}/$r{domain}" unless($r{source});
	$r{url}=$r{target};
	$r{level}=$r{target_level};
	delete @r{qw/target target_level/};
    return \%r;
}



sub get_passdown {
	my $result = shift;

}

sub set_callback {
	my $name = shift;
	$CALLBACK{$name} = [@_];
}

sub callback_apply_rule {
	if(!$CALLBACK{'apply_rule'}) {
		print STDERR "Callback \"apply_rule\" not definied\n";
	}
	else {
		my @callback = @{$CALLBACK{apply_rule}};
		my $func = shift @callback;
		&$func(@_,@callback);
	}
}

sub new_response {
	my $url = shift;
	my $rule = shift;
	my $result = shift;
	my %response = (
		url=>$url,
		rule=>$rule,
		action=>$rule->{action},
	);
	if(!$result) {
		$response{error} = "Rule defined, but return NOTHING";
	}
	elsif(!ref $result) {
		$response{data} = [$result,@_];
	}
	elsif(ref $result eq 'ARRAY') {
		$response{data} = $result;
	}
	else {
		#$result->{action} = $rule->{action} unless($result->{action});
		unless(defined $result->{level}) {
			$result->{level} = $rule->{level} if($result->{samelevel} || $result->{same_level});
		}
		unless(defined $result->{level}) {
			$result->{level} = $rule->{level}  - 1;
		}

		if($result->{data}) {
			$result->{count} = @{$result->{data}};
			delete $result->{data} if($result->{count}<1);
		}

		if($result->{pass_data} && @{$result->{pass_data}}) {
			$result->{nextlevel} = {} unless($result->{next_level});
			my $nl = $result->{nextlevel};
			$nl->{data} = [] unless($nl->{data});
			if($result->{pass_name} && @{$result->{pass_name}}) {
				my $idx = 0;
				foreach(@{$result->{pass_data}}) {
					push @{$nl->{data}},$_ . "\t" . $result->{pass_name}[$idx];
					$idx++;
				}
			}
			else {
				push @{$nl->{data}},@{$result->{pass_data}};
			}
			if(defined $result->{pass_count}) {
				$nl->{count} = $result->{pass_count};
			}
			else {
				$nl->{count} = @{$nl->{data}};
			}
			$nl->{level} = $result->{level};
			$result->{nextlevel} = new_response($url,$rule,$nl);
		}
		else {
			delete $result->{nextlevel};
		}
		$result->{title} = $result->{work_dir} unless($result->{title});
		delete @$result{qw/pass_data pass_name work_dir pass_count/};
		%response = (%response,%$result);
		foreach(keys %response) {
			delete $response{$_} unless(defined $response{$_});
		}
	}
	if($response{error}) {
		return undef,\%response;
	}
	else {
		return 1,\%response;
	}
}

my %CACHED_RULE = ();
sub get_rule_handler {
	my $info = shift;
	if(!ref $info) {
		unshift @_,$info;
		$info = parse_rule(@_);
	}
	if(!($info || ref $info || %{$info})) {
		return {error=>'Rule not defined'};#,undef;
	}
	my $source = $info->{source};
	$info->{version} = 1;
	if(open FI,'<',$source) {
		my $count = 0;
		while(<FI>) {
			last if($count > 20);
			if(index($_,'MyPlace::URLRule::Rule')>0) {
				$info->{version} = 2;
				last;
			}
			$count++;
		}
		close FI;
	}
	else {
		return {error=>"Rule not defined: file not accessiable:$source"};#,undef;
	}
	my $id = $source;
	if($CACHED_RULE{$id}) {
		return $CACHED_RULE{$id};
	}
	
	if($info->{version} >= 2) {
		my $r;
		if(!($r = do $source)) {
			if($@) {
				return {error=>"Compiling '$source' failed.\n$@"};
			}
			elsif(!defined $r) {
				return {error=>"File '$source' compiled, but return nothing.\n$!"};
			}
			elsif(!$r) {
				return {error=>"File '$source' compiled, but return false."};
			}
			else {
				return {error=>"File '$source' compiled, but return no MyPlace::URLRule::Rule"};
			}
		}
		elsif(!ref $r) {
			return {error=>"File '$source' compiled, but return no MyPlace::URLRule::Rule"};
		}
		else {
			$r->{source} = $source;
			$r->{rule} = $info;
			$CACHED_RULE{$id} = $r;
			return $r;
		}
	}

	my $package = "MyPlace::URLRule::Rule::$id";
	$package =~ s/[\/\\\.-]/_/g;
	#app_message "Importing rule $source\n";
	no warnings "redefine";
	eval "package $package;do \"$source\";"; 
	eval "package $package;" . '
		sub apply {
			my $self = shift(@_);
			my $url = shift(@_);
			my $level = shift(@_);
			my $info = MyPlace::URLRule::parse_rule($url,$level,@_);
			$info->{options} = $self->{options};
			$info = {%{$self->{rule}},%$info};
			my ($status,@result) = apply_rule($url,$info);
			my %result;
			if(!@result) {
				if($status) {
					%result = (data=>[$status]);
				}
				else {
					%result = (error=>"Nothing to do");
				}
			}
			elsif(!$status) {
				%result = (error=>$result[0]);
			}
			else {
				%result = ($status,@result);
			}
		    if($result{"#use quick parse"}) {
				%result = MyPlace::URLRule::urlrule_quick_parse(url=>$url,%result);
		    }
			return MyPlace::URLRule::new_response($url,$info,\%result);
		}
	';
=no eval
	no warnings "redefine";
	package MyPlace::URLRule::RuleBridge;
	do $source;
	if(!defined ${MyPlace::URLRule::RuleBridge::}{apply}) {
		${MyPlace::URLRule::RuleBridge::}{apply} = sub {
			my $self = shift;
			my $info = MyPlace::URLRule::parse_rule(@_);
			return MyPlace::URLRule::RuleBridge::apply_rule($info->{url},$info);
		}
	}
	if(!defined (*MyPlace::URLRule::RuleBridge::new)) {
		*MyPlace::URLRule::RuleBridge::new = sub {
			my $class = shift;
			return bless {},$class;
		};
	}
=cut
	no warnings "redefine";
	print STDERR "$@\n" if($@);
	$@=undef;
	package MyPlace::URLRule;
	my $rule = bless {
			source=>$source,
			package=>$package,
			rule=>$info,
		},$package;
	$CACHED_RULE{$id} = $rule;
	return $rule;
}

sub get_rule {
	goto &parse_rule;
}

sub get_handler {
	my $rule = shift;
	if(!ref $rule) {
		$rule = get_rule($rule,@_);
	}
	if(ref $rule) {
		return get_rule_handler($rule,@_);
	}
	else {
		return {error=>"No handler found!"};
	}
}

sub request {
	my $arg1 = shift;
	my @args = @_;
	my $rule;
	if(!ref $arg1) { 
		$rule = parse_rule($arg1,@args);
		@args = ();
	}
	else {
		$rule = $arg1;
	}
	my $handler = get_handler($rule);
	if($handler->{error}) {
		print STDERR "Error: ",$handler->{error},"\n";
		return 0;
	}
#	my $request = $rule;
	my $request = (@args > 0) ? parse_rule(@args) : $rule;
	return $handler->apply(@$request{qw/url level action/});
}


sub apply_rule {
    my $rule = shift;
    unless($rule and ref $rule and %{$rule}) {
        return undef,"Invalid rule, could not apply!";
    }
	my $handler = get_rule_handler($rule);
	if($handler->{error}) {
		print STDERR "Error: ",$handler->{error},"\n";
		return 0;
	}
	return $handler->apply($rule->{url},$rule->{level},$rule->{action});
}

sub exp_runner {
	my $exp = shift;
	my $html = shift;
	my $url = shift;
	my @data = @_;
	
	my $r;
	if(!$exp) {
		$r = $data[0];
	}
	elsif(ref $exp) {
		$r = &$exp($html,$url,@data);
	}
	else {
		$r = eval($exp);
		if($@) {
			print STDERR "Error while eval($exp):$@\n";
		}
	}
	return $r;
}

sub urlrule_quick_parse {
    my %args = @_;
    my $url = $args{url};
	my $html = $args{html};

    die("Error 'url=>undef'\n") unless($url);
    my $title;
#    my %rule = %{$args{rule}};
    my ($title_exp,$title_map,
		$data_exp,$data_map,
		$pass_exp,$pass_map,$pass_name_exp,$pass_name_map,
		$pages_exp,$pages_map,$pages_pre,$pages_suf,$pages_start,$pages_margin,
		$pages_limit,
		$charset) = @args{qw/
        title_exp title_map
        data_exp data_map
		pass_exp pass_map pass_name_exp pass_name_map 
        pages_exp pages_map pages_pre pages_suf pages_start pages_margin
		pages_limit
        charset
    /};
	
	my @curl = ($url,'-v',(defined $charset ? "charset:$charset" : undef),'--referer',$url);
	push @curl,'--compressed' if($args{compressed});
    $html = get_url(@curl) unless($html);
	return (
		'Error',
		"Failed restriving $url",
	) unless($html);
    my @data;
    my @pass_data;
    my @pass_name;
	my %h_data;
	my %h_pass;
    $data_map = '$1' unless($data_map);
    $pass_map = '$1' unless($pass_map);
	my %LOCAL_VAR;
    $pass_name_map = $pass_name_exp unless($pass_name_map);
	if($args{data}) {
		@data = @{$args{data}};
	}
    elsif($data_exp) {
        while($html =~ m/$data_exp/g) {
			my $r = &exp_runner($data_map,$html,$url,$1,$2,$3,$4,$5,$6,$7,$8,$9);
			#print STDERR "$data_exp => $data_map => $r\n";
			next unless($r);
			next if($h_data{$r});
            push @data,$r;
			$h_data{$r} = 1;
        }
    }
	if($args{pass_data}) {
		@pass_data = @{$args{pass_data}};
		@pass_name = @{$args{pass_name}} if($args{pass_name});
	}
    elsif($pass_exp) {
        while($html =~ m/$pass_exp/g) {
			my $r = &exp_runner($pass_map,$html,$url,$1,$2,$3,$4,$5,$6,$7,$8,$9);
			next if($h_pass{$r});
            push @pass_data,$r;
			$h_pass{$r} = 1;
			if($pass_name_map) {
				$r = &exp_runner($pass_name_map,$html,$url,$1,$2,$3,$4,$5,$6,$7,$8,$9);
				push @pass_name,$r if(defined $r);
			}	
        }
    }
    elsif($pages_exp) {
		my $pages =  &parse_pages(
				source=>$url,
				data=>$html,
				exp=>$pages_exp,
				map=>$pages_map,
				prefix=>$pages_pre,
				suffix=>$pages_suf,
				start=>$pages_start,
				margin=>$pages_margin,
				limit=>$pages_limit,
		);
		if(!@pass_data) {
			@pass_data = @{$pages};
		}
		else {
			push @pass_data,@{$pages};
		}
    }
	if($args{title}) {
		$title = $args{title};
	}
    elsif($title_exp) {
        $title_map = '$1' unless($title_map);
        if($html =~ m/$title_exp/) {
			$title = &exp_runner($title_map,$html,$url,$1,$2,$3,$4,$5,$6,$7,$8,$9);
        }
    }
    return (
        count=>scalar(@data),
        data=>[@data],
        pass_count=>scalar(@pass_data),
        pass_data=>[@pass_data],
        pass_name=>[@pass_name],
        base=>$url,
        no_subdir=>(@pass_name ? 0 : 1),
        title=>$title,
        %args,
    );
}

sub new {
	my $class = shift;
	my $self = bless {},$class;
	$self->rule(@_);
	return $self;
}

sub process {
	my $self = shift;
	if(!$self->{default_rule}) {
		$self->rule(@_);
	}
	my $rule = $self->{default_rule};
	return request($rule,@_);
}

sub rule {
	my $self = shift;
	delete $self->{default_rule};
	return unless(@_);
	$self->{default_rule} = get_rule(@_);
	return $self->{default_rule};
}

sub error {
	my $r = shift;
	return unless($r);
	if($r && ref $r) {
		print STDERR "Error: $r->{error}\n";
	}
	else {
		print STDERR "Error: $r\n";
	}
}

sub post_process {
	my $self = shift;
	my $status = shift;
	my $result = shift;
	if(!($status or $result)) {
		error("Invalid request");
		return undef;
	}
	if(!$result) {
		error("Empty response");
		return undef;
	}
	elsif(!ref $result) {
		if(!$status) {
			error($result);
			return undef;
		}
		else {
			print STDERR "$result\n";
			return undef;
		}
	}
	return $result;
}

1;

package MyPlace::MyPlace::RuleBridge::Object;
sub new {
	my $class = shift;
	return bless {},$class;
}
sub apply {
	my $self = shift;
	my $info = parse_rule(@_);
	return MyPlace::URLRule::RuleBridge::apply_rule($info->{url},$info);
}

1;

__END__

=pod

=head1  NAME

MyPlace::URLRule - Common routines form urlrule

=head1  SYNOPSIS

    use MyPlace::URLRule;

    sub process_rule
    {
        my ($status1,$rule,$result) 
            = urlrule_process_args(@_);
        if($status1) {
            my ($status2,$pass_count,@pass_args) 
                = urlrule_process_result($rule,$result);
            if($status2 and $pass_count>0) 
            {
                foreach my $args_ref (@pass_args) {
                    process_rule(@{$_});
                }
            }
        }
    }
    process_rule(undef,@ARGV);
        
=head1 DESCRIPTION

Common rountines for urlrule_action urlrule_task ...

=head1  CHANGELOG

    2010-06-12  xiaoranzzz  <xiaoranzzz@myplace.hell>
        
        * add POD document
        * add function perform_action()
        * add $URLRULE_DIRECTORY/common for rules not differ in level.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@myplace.hell>

=cut


