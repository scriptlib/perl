#!/usr/bin/perl -w
package MyPlace::URLRule;
use URI;
use URI::Escape;
use MyPlace::Script::Message;
use strict;
use Cwd;

BEGIN {
    use Exporter ();
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw($URLRULE_DIRECTORY &urlrule_process_data &urlrule_process_passdown &urlrule_process_args &urlrule_process_result &get_domain &get_rule_dir &build_url &parse_rule &urlrule_do_action &execute_rule &urlrule_get_passdown urlrule_parse_pages);
}

#my $URLRULE_DIRECTORY = "$ENV{XR_PERL_SOURCE_DIR}/urlrule";
our $URLRULE_DIRECTORY = "$ENV{XR_PERL_SOURCE_DIR}/urlrule";
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
    return $URLRULE_DIRECTORY;
}
sub get_domain($) {
    my $url = shift;
	$url =~ s/^.*?:\/+//g;
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
    my $domain = $r{domain};
    do 
    {
        for my $directory (
            "$URLRULE_DIRECTORY/$r{level}",
            "$URLRULE_DIRECTORY/common",
            )
        {
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
                    $r{source} = "$directory/$basename";
                    last;
                }
            }
            last if($r{source});
        }
    } while($domain =~ s/^[^\.]*\.// and !$r{source});
    $r{source} 
        = "$URLRULE_DIRECTORY/$r{level}/$r{domain}" unless($r{source});
    return \%r;
}

sub build_url($$) {
    my ($base,$url) = @_;
    $url = URI->new_abs($url,$base) if($base);
    return $url;
}

sub callback_process_data {
    my $from = shift;
    app_message("callback:$from\n") if($from);
    goto &urlrule_process_data;
#    &main::process_data(@_);
}
sub callback_process_passdown {
    my $from = shift;
    app_message("callback:$from\n") if($from);
    goto &urlrule_process_passdown;
#    &main::process_passdown(@_);
}
sub callback_do_action {
    my $from = shift;
    app_message("callback:$from\n") if($from);
    goto &urlrule_do_action;
#    &main::do_action(@_);
}


sub urlrule_process_data {
    my $rule_ref = shift;
    return unless(ref $rule_ref);
    return unless(%{$rule_ref});
    my $result_ref = shift;
    return unless(ref $result_ref);
    return unless(%{$result_ref});

    return unless($result_ref->{data});
    my %rule = %{$rule_ref};
    my %result = %{$result_ref};
    
    my $url=$rule{"url"};
    my $level = $rule{"level"};
    my $action = $rule{"action"};
    my @args = $rule{"args"} ? @{$rule{"args"}} : ();
    my $msghd = $result{work_dir} ? "[". $result{work_dir} . "]" : "";
    my $count = @{$result{data}};
    app_message($msghd , "Level $level>>","Get $count Lines\n");
    #,performing action $action..\n");
    my ($status,@message) = callback_do_action(undef,$result_ref,$action,@args);
    if($status) {
        app_message($msghd,"Level $level>>",@message,"\n");
        return 1;
    }
    else {
        app_warning($msghd,"Level $level>>",@message,"\n");
        return undef;
    }
}


sub urlrule_process_passdown {
    my $rule_ref = shift;
    return unless(ref $rule_ref);
    return unless(%{$rule_ref});
    my $result_ref = shift;
    return unless(ref $result_ref);
    return unless(%{$result_ref});
    my $msghd="";
    my ($count,@passdown) = urlrule_get_passdown($rule_ref,$result_ref);
    my $level = $rule_ref->{level};
    if($count) {
        app_message($msghd,"Level $level>>","Get $count rules to pass down\n");
    }
    else {
        return undef;
        return 1;
    }
    my $CWD = getcwd;
    foreach(@passdown) {
        my($status1,$rule,$result) = urlrule_process_args(@{$_});
        if($status1)
        {
            my($status2,$pass_count,@pass_args)
                = urlrule_process_result($rule,$result);
            my $CWD = getcwd;
            if($status2) {
                foreach(@pass_args) {
                    callback_process_passdown(undef,@{$_});
                    chdir $CWD;
                }
            }
        }
        chdir $CWD;
    }
    return 1;
}

sub delete_dup {
    my %holder;
    foreach(@_) {
        $holder{$_} = 1;
    }
    return keys %holder;
}


use MyPlace::Curl;
sub urlrule_quick_parse {
    my %args = @_;
    my $url = $args{url};
    die("Error 'url=>undef'\n") unless($url);
    my $title;
#    my %rule = %{$args{rule}};
    my ($title_exp,$title_map,$data_exp,$data_map,$pass_exp,$pass_map,$pass_name_exp,$pages_exp,$pages_map,$pages_pre,$pages_suf,$pages_start,$charset) = @args{qw/
        title_exp
        title_map
        data_exp
        data_map
        pass_exp
        pass_map
        pass_name_exp
        pages_exp
        pages_map
        pages_pre
        pages_suf
        pages_start
        charset
    /};
    my $http = MyPlace::Curl->new();
    my (undef,$html) = $http->get($url,(defined $charset ? "charset:$charset" : undef));
    my @data;
    my @pass_data;
    my @pass_name;
    $data_map = '$1' unless($data_map);
    $pass_map = '$1' unless($pass_map);
    if($title_exp) {
        $title_map = '$1' unless($title_map);
        if($html =~ m/$title_exp/g) {
            $title = eval($title_map);
        }
    }
    if($data_exp) {
        while($html =~ m/$data_exp/g) {
            push @data,eval($data_map);
        }
    }
    if($pass_exp) {
        while($html =~ m/$pass_exp/g) {
            push @pass_data,eval($pass_map);
            if($pass_name_exp) {
                push @pass_name,eval($pass_name_exp);
            }
        }
    }
    elsif($pages_exp) {
        $pages_start = 2 unless(defined $pages_start);
        my $last = $pages_start - 1; 
        my $pre = "";
        my $suf = "";
        while($html =~ m/$pages_exp/g) {
            if(eval($pages_map) > $last) {
                    $last = eval($pages_map);
                    $pre = eval($pages_pre) if($pages_pre);
                    $suf = eval($pages_suf) if($pages_suf);
            }
        }
        if($last >= $pages_start) {
            @pass_data = map "$pre$_$suf",($pages_start .. $last);
        }
        push @pass_data,$url;
    }
    @data = delete_dup(@data) if(@data);
    @pass_data = delete_dup(@pass_data) if(@pass_data and (!@pass_name));
    return (
        count=>scalar(@data),
        data=>[@data],
        pass_count=>scalar(@pass_data),
        pass_data=>[@pass_data],
        pass_name=>[@pass_name],
        base=>$url,
        no_subdir=>(@pass_name ? 0 : 1),
        work_dir=>$title,
        %args,
    );
}

sub urlrule_process_args 
{
    my ($dir,@args) = @_;
    my $rule = parse_rule(@args);
    unless($rule)
    {
        app_message("Invalid args : " . join(" ",@args),"\n");
        return undef;
    }
    my $level = $rule->{level};
    if($dir)
    {
        mkdir $dir unless(-d $dir);
        if(!chdir $dir) {
            app_error("Level $level>>","$!\n");
            return undef;
        }
    }
    my $url = $rule->{url};
    my $source = $rule->{"source"};
    my $msghd = "Level $level>>";
    app_message($msghd,"For \"$url\" ...\n");
    app_message($msghd,"Found rule: \"$source\"\n");
    unless(-f $source) {
        app_error($msghd,"File not found: $source\n");
        return undef;
    }
    app_message($msghd,"Applying it...\n");
    unless(my $do_exit = do $source) { 
        die("couldn't parse $source:\n$@") if($@);
        #die("couldn't do $source:$!") unless defined $do_exit;
        #die("couldn't run $source") unless $do_exit;
    }
    my %result = &apply_rule($url,$rule);
    if($result{"#use quick parse"}) {
        %result = &urlrule_quick_parse('url'=>$url,%result);
    }
    if($result{work_dir}) {
        $result{work_dir} = &unescape_text($result{work_dir});
    }
    return 1,$rule,\%result;
}

sub execute_rule {
    my %rule = %{$_[0]};
    my $url = $rule{url};
    my $source = $rule{"source"};
    my @args = $rule{"args"} ? @{$rule{"args"}} : ();
    unless(-f $source) {
        return undef,"File not found: $source";
    }
#    $! = undef;
    no warnings 'all';
    unless(my $do_exit = do $source) { 
        return undef,"couldn't parse $source:\n$@" if($@);
        #die("couldn't do $source:$!") unless defined $do_exit;
        #die("couldn't run $source") unless $do_exit;
    }
    use warnings;
    my %result = &apply_rule($url,\%rule);
    if($result{"#use quick parse"}) {
        %result = &urlrule_quick_parse('url'=>$url,%result);
    }
    if($result{work_dir}) {
        $result{work_dir} = &unescape_text($result{work_dir});
    }
    return 1,\%result;
}

sub urlrule_process_result
{
    #return #status,pass_count,@pass_args;
    my($rule,$result,$p_action,@p_args) = @_;
    unless($rule and ref $rule and %{$rule})
    {
        app_error("Invaild Rule\n");
        return undef;
    }
    my $level = $rule->{"level"};
    unless($result and ref $result and %{$result})
    {
        app_error("Level $level>>","Invalid Result\n");
        return undef;
    }
    if($result->{work_dir}) {
        unless( -d $result->{work_dir}) {
            app_message "Creating directory : \"$result->{work_dir}\"...\n";
            mkdir $result->{work_dir};
        }
        chdir $result->{work_dir} or return undef,$!;
    }
    my $action;
    my @args;
    if($p_action) 
    {
        $action = $p_action;
        @args = @p_args;
    }
    else
    {
        $action = $rule->{action};
        @args = @{$rule->{args}} if($rule->{args});
    }
    my $count = $result->{data} ? @{$result->{data}} : 0;
#    if($count > 0)
#    {
        app_message("Level $level>>","Get $count Lines\n");
        #,performing action \"$action\" ...\n") if($count > 0);
        my($action_status,$action_message) = callback_do_action(undef,$result,$action,@args);
        if($action_status) {
            app_message "Level $level>>$action_message\n";
        }
        else {
            app_warning "Level $level>>$action_message\n" if($action_message);
        }
#    }
    my ($pass_count,@pass_args) = urlrule_get_passdown($rule,$result);
    app_message "Level $level>>", "Get $pass_count rules to pass down\n" if($pass_count);
    return 1,$pass_count,@pass_args;
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
#    $text =~ s/[_-]+/ /g;
    $text =~ s/[\:]+/, /g;
    $text =~ s/[\\\<\>"\^\&\*\?]+//g;
    $text =~ s/\s{2,}/ /g;
    $text =~ s/(?:^\s+|\s+$)//;
    return $text;
}

sub make_url {
    my $line = shift;
    my $base = shift;
    if($line =~ /^([^\t]+)\t+(.+)$/) {
        return URI->new_abs($1,$base) . "\t" . $2;
    }
    else {
        return URI->new_abs($line,$base);
    }
}

sub urlrule_do_action {
    my ($result_ref,$action,@args) = @_;
    return undef,"No results" unless(ref $result_ref);
    return undef,"No results" unless(%{$result_ref});
    my %result = %{$result_ref};
    my $msg="";
    $msg = "[" . $result{work_dir} . "]" if($result{work_dir});

    return undef,"No results" unless($result{data});
    if(ref $result{data} eq 'SCALAR') {
        $result{data} = [$result{data}];
    }
    app_message("Do Action>>",getcwd,"\n");
    my $file=$result{file};
    $file =~ s/\s*\w*[\/\\]\w*\s*//g if($file);
    my $pipeto=$action ? $action : $result{action};
    $pipeto = $pipeto ? $pipeto : $result{pipeto} ;
    if($file) {
        if (-f $file) {
            return undef,$msg . "Ingored (File exists)...";
        }
        else {
            open FO,">:utf8",$file or die("$!\n");
            print FO @{$result{data}};
            close FO;
            return 1,$msg . "Action File ($file) OK.";
        }
    }
    elsif($action and $action eq 'dump') {
        use Data::Dumper;
        local $Data::Dumper::Purity = 1; 
        print Data::Dumper->Dump([$result_ref],qw/*result_ref/);
        return 1, $msg . "Action DUMP OK.";
    }
    elsif($pipeto) {
        $pipeto .= ' "' . join('" "',@args) . '"' if(@args);
        open FO,"|-",$pipeto;
        foreach my $line (@{$result{data}}) {
            $line = &make_url($line,$result{base}) if($result{base});
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
            $line = &make_url($line,$result{base}) if($result{base});
            &process_data($line,\%result);
        }
        return 1,$msg . "Action Hook OK.";
    }
    else {
        foreach my $line(@{$result{data}}) {
            $line = &make_url($line,$result{base}) if($result{base});
            print $line,"\n";
        }
        return 1,$msg . "OK.";
    }
}

sub urlrule_get_passdown {
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
    push @ACTARG,@args if(@args);
    my @actions;
    my $count=@data;
    for(my $i=0;$i<$count;$i++) {
        my @current;
        push @current, $result{no_subdir} ? undef : $subdirs[$i];
        push @current, $data[$i],@ACTARG;
        push @current, $result{pass_arg}->[$i] if($result{pass_arg});
        push @actions,\@current;
    }
    return $count,@actions;
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


