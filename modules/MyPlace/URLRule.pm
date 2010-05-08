#!/usr/bin/perl -w
package MyPlace::URLRule;

BEGIN {
    use Exporter ();
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw(&get_domain &get_rule_dir &build_url &parse_rule);
}

my $RULE_DIRECTORY = "$ENV{XR_PERL_SOURCE_DIR}/urlrule";
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
    $r{source} = "$rule_dir/$r{domain}";
    for my $fn ($r{domain},"$r{domain}.pl","www.$r{domain}","www.$r{domain}.pl") {
        if( -f "$rule_dir/$fn" ) {
            $r{source}="$rule_dir/$fn";
        }
    }
    return \%r;
}

sub build_url($$) {
    my ($base,$url) = @_;
    $url = URI->new_abs($url,$base) if($base);
    return $url;
}

return 1;
