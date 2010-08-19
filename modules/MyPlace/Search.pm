package MyPlace::Search;
BEGIN {
#    sub debug_print {
#        return unless($ENV{XR_PERL_MODULE_DEBUG});
#        print STDERR __PACKAGE__," : ",@_;
#    }
#    &debug_print("BEGIN\n");
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw(build_keyword build_url get_url);
}

use LWP::UserAgent;
my $HTTP;

sub build_keyword {
    my $keyword = shift;
    my $no_or = shift;
    my @keywords;
    while($keyword =~ m/["']([^"']+)["']|([^\s]+)/g)
    {
        my $word = $1 ? $1 : $2;
        next unless($word);
        $word =~ s/\s+/+/g;
        push @keywords,"\"$word\"";
    }
    return $no_or ? join("+",@keywords) : join("+OR+",@keywords);
}
sub build_url {
    my ($base,$p_ref) = @_;
    my %params = %{$p_ref};
    return $base . join("&",map ("$_=" . $params{$_},keys %params));
}
sub get_url {
    my ($URL,$referer,$decoder) = @_;
    print STDERR "Retrieving $URL ...";
    if(!$HTTP) {
        $HTTP = LWP::UserAgent->new();
        $HTTP->agent("Mozilla/5.0");# (X11; U; Linux i686; en-US; rv:1.9.0.3) Gecko/2008092416 Firefox/3.0.3 Firefox/3.0.1");
    }
    my $res = $HTTP->get($URL,"referer"=>$referer ? $referer : $URL);
    print STDERR " [" . $res->code . "]\n";
    if(wantarray) {
        return $res, ($decoder ? $decoder->decode($res->content) : $res->content);
    }
    else {
        return $res;
    }
}

1;
