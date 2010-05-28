#!/usr/bin/perl -w
package MyPlace::URLRule;
use URI;
use URI::Escape;

BEGIN {
    use Exporter ();
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw(&get_domain &get_rule_dir &build_url &parse_rule &do_action &execute_rule &make_passdown);
}

my $RULE_DIRECTORY = "$ENV{XR_PERL_SOURCE_DIR}/urlrule";
sub strnum($$) {
    my $num=shift;
    my $len=shift;
    my $o_len = length($num);
    if(!$len or $len<=0 or $len<=$o_len) {
        return $num;
    }
    else {
        return "0" x ($len-$o_len) . $num;
    }
}
sub get_rule_dir() {
    return $RULE_DIRECTORY;
}
sub get_domain($) {
    my $url = shift;
	$url =~ s/^.*:\/+//g;
	$url =~ s/\/.*//g;
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

sub get_rule(\$) {
    my %rule = %{ shift(@_) };
    my $domain=get_domain( shift );
    my $level=shift;$level=0 unless($level && $level =~ /^\d+$/);
    return "$dirname/$domain.pl";
}

sub parse_rule(@) {
    my %r;
    $r{url} = shift;

    if($r{url} =~ /^local:([^\/]+)/) {
        $r{"local"} = $1;
        $r{url} =~ s/^local:/file_/;
        if($r{url} =~ /^file_[^\/]+\/(.*)$/) {
            use Cwd 'abs_path';
            $r{"local_path"} = abs_path($1);
        }
    }
    if($r{url} !~ /^http:\/\//i) {
        $r{url} = "http://" . $r{url};
    }
    $r{level} = shift;
    if($r{level} and $r{level} =~ /^domain:(.*)$/) {
        $r{domain} = $1;
        $r{level} = shift;
    }
    $r{domain} = get_domain($r{url}) unless($r{domain});

    if($r{level}) {
       if($r{level} !~ /^\d+$/) {
        unshift @_,$r{level};
        $r{level} = 0;
       }
    }
    else {
        $r{level} = 0;
    }
    $r{action} = shift;
    $r{action} = "" unless($r{action});
    @{$r{args}} = @_;
    my $rule_dir = $RULE_DIRECTORY . "/" . $r{level};
    for my $fn ($r{domain},"$r{domain}.pl","www.$r{domain}","www.$r{domain}.pl") {
        if( -f "$rule_dir/$fn" ) {
            $r{source}="$rule_dir/$fn";
        }
    }
    unless($r{source}) {
        my $domain = $r{domain};
        while($domain =~ /[^\.]+\.[^\.]+\./) {
            $domain =~ s/^[^\.]*\.//;
            for my $fn ($domain, $domain . ".pl", "www.$domain", "www.$domain" . ".pl") {
                $r{source}="$rule_dir/$fn" if(-f "$rule_dir/$fn");
            }
        } 
    }
    $r{source} = "$rule_dir/$r{domain}" unless($r{source});
    return \%r;
}

sub build_url($$) {
    my ($base,$url) = @_;
    $url = URI->new_abs($url,$base) if($base);
    return $url;
}

sub execute_rule {
    my %rule = @_;
    my $url = $rule{url};
    my $source = $rule{"source"};
    my @args = $rule{"args"} ? @{$rule{"args"}} : ();
    unless(-f $source) {
        return undef,"File not found: $source";
    }
    $! = undef;
    do $source; 
    return undef,$! if($!);
    my %result = &apply_rule($url,\%rule);
    if($result{work_dir}) {
        $result{work_dir} = &unescape_text($result{work_dir});
    }
    return 1,\%result;
}


sub unescape_text {
    my %ESCAPE_MAP = (
        "&lt;","<" ,"&gt;",">",
        "&amp;","&" ,"&quot;","\"",
        "&agrave;","à" ,"&Agrave;","À",
        "&acirc;","â" ,"&auml;","ä",
        "&Auml;","Ä" ,"&Acirc;","Â",
        "&aring;","å" ,"&Aring;","Å",
        "&aelig;","æ" ,"&AElig;","Æ" ,
        "&ccedil;","ç" ,"&Ccedil;","Ç",
        "&eacute;","é" ,"&Eacute;","É" ,
        "&egrave;","è" ,"&Egrave;","È",
        "&ecirc;","ê" ,"&Ecirc;","Ê",
        "&euml;","ë" ,"&Euml;","Ë",
        "&iuml;","ï" ,"&Iuml;","Ï",
        "&ocirc;","ô" ,"&Ocirc;","Ô",
        "&ouml;","ö" ,"&Ouml;","Ö",
        "&oslash;","ø" ,"&Oslash;","Ø",
        "&szlig;","ß" ,"&ugrave;","ù",
        "&Ugrave;","Ù" ,"&ucirc;","û",
        "&Ucirc;","Û" ,"&uuml;","ü",
        "&Uuml;","Ü" ,"&nbsp;"," ",
        "&copy;","\x{00a9}",
        "&reg;","\x{00ae}",
        "&euro;","\x{20a0}",
    );
    my $text = shift;
    return unless($text);
    foreach (keys %ESCAPE_MAP) {
        $text =~ s/$_/$ESCAPE_MAP{$_}/g;
    }
    $text =~ s/&#(\d+);/chr($1)/eg;
    $text = uri_unescape($text);
    $text =~ s/[_-]+/ /g;
    $text =~ s/[\:]+/, /g;
    $text =~ s/[\\\<\>"\^\&\*\?]+//g;
    $text =~ s/\s{2,}/ /g;
    $text =~ s/(?:^\s+|\s+$)//;
    return $text;
}

sub do_action {
    my ($result_ref,$action,@args) = @_;
    return undef,"No results" unless(ref $result_ref);
    return undef,"No results" unless(%{$result_ref});
    my %result = %{$result_ref};
    return undef,"No results" unless($result{data});
    my $msg="";
    if($result{work_dir}) {
        mkdir $result{work_dir} unless(-d $result{work_dir});
        chdir $result{work_dir} or return undef,$!;
        $msg = "[" . $result{work_dir} . "]";
    }
    if(ref $result{data} eq 'SCALAR') {
        $result{data} = [$result{data}];
    }
    my $file=$result{file};
    $file =~ s/\s*\w*[\/\\]\w*\s*//g if($file);
    my $pipeto=$action ? $action : $result{action};
    $pipeto = $pipeto ? $pipeto : $result{pipeto} ;
    if($file) {
        if (-f $file) {
            return undef,$msg . "Ingored (File exists)...";
        }
        else {
            open FO,">",$file or die("$!\n");
            print FO @{$result{data}};
            close FO;
            return 1,$msg . "Action File ($file) OK.";
        }
    }
    elsif($pipeto) {
        $pipeto .= ' "' . join('" "',@args) . '"' if(@args);
        open FO,"|-",$pipeto;
        foreach my $line (@{$result{data}}) {
            $line = URI->new_abs($line,$result{base}) if($result{base});
            print FO $line,"\n";
        }
        close FO;
        return 1,$msg . "Action Pipeto ($pipeto) OK.";
    }
    elsif($result{hook}) {
        my $index=0;
        foreach my $line(@{$result{data}}) {
            $index ++;
            my @msg = ref $line ? @{$line} : ($line);
            $line = URI->new_abs($line,$result{base}) if($result{base});
            process_data($line,\%result);
        }
        return 1,$msg . "Action Hook OK.";
    }
    else {
        foreach my $line(@{$result{data}}) {
            $line = URI->new_abs($line,$result{base}) if($result{base});
            print $line,"\n";
        }
        return 1;$msg . "OK.";
    }
}

sub make_passdown {
    my $rule_ref = shift;
    return unless(ref $rule_ref);
    return unless(%{$rule_ref});
    my $result_ref = shift;
    return unless(ref $result_ref);
    return unless(%{$result_ref});
    return unless($result_ref->{pass_data});
    my %rule = %{$rule_ref};
    my %result = %{$result_ref};
    my $level = $rule{"level"} - 1;
    my $action = $rule{"action"};
    my @args = $rule{"args"} ? @{$rule{"args"}} : ();
    if(ref $result{pass_data} eq 'SCALAR') {
        $result{pass_data} = [$result{pass_data}];
    }
    $result{pass_arg}="" unless($result{pass_arg});
    my @data;
    if($result{base}) {
        @data= map URI->new_abs($_,$result{base})->as_string,@{$result{pass_data}};
    }
    else {
        @data=@{$result{pass_data}};
    }
    my @subdirs;
    @subdirs=@{$result{pass_name}} if($result{pass_name});
    unless($result{no_subdir} and @subdirs) {
        my $len = length(@data);
        for(my $i=0;$i<@data;$i++) {
            push(@subdirs,strnum($i+1,$len));
        }
    }
    $level = $result{pass_level} if(exists $result{pass_level});
    my @ACTARG=($level,$action);
    unshift (@ACTARG,"domain:" . $result{pass_domain}) if($result{pass_domain});
    push @ARTARG,@args if(@args);
    my @actions;
    my $count=@data;
    for(my $i=0;$i<$count;$i++) {
        my @current;
        push @current, $result{no_subdir} ? undef : $subdirs[$i];
        push @current, $data[$i],@ACTARG;
        push @current, $result{pass_arg}->[$i] if($result{pass_arg});
        push @actions,\@current;
    }
    return $level,$count,@actions;
}

return 1;
