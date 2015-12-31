#!/usr/bin/perl -w
package MyPlace::URL;
BEGIN {
    use Exporter ();
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw(&get_base &get_domain &get_root &get_full);
}

#http://www.google.com/intl/
sub get_base($) {
    my $result=shift; 
    if (! $result) {return "";}
    if ($result !~ /^http:\/\//i) {
        $result = "http://" . $result;
        $result =~ s/^http:\/\/\/*/http:\/\//;
    }
    $result =~ s/http:\/\/(.*)\/[^\/]*$/http:\/\/$1/;
    $result .= "/";
    $result =~ s/([^:\/])\/\//$1\//g;
    return $result;
}

sub get_domain($) {
    my $result=shift;
    $result =~ s/^.*:\/\///g;
    $result =~ s/\/.*$//;
    return $result;
}

#http://www.google.com
sub get_root($) {
    my $result=shift;
    if ($result !~ /^http:\/\//i) {
        $result = "http://" . $result;
        $result =~ s/^http:\/\/\/*/http:\/\//;
    }
    $result =~ s/^http:\/\/([^\/]*).*/http:\/\/$1/;
    return $result;
}

sub get_full($$@) {
    my $base = shift;
    my $root = shift;
    my @result=();
    foreach(@_) {
        my $url=$_;
        if ($url =~ /^\//) {
            $url = $root . $url;
        }
        else {
            if ($url !~ /^http:\/\//i) {
                $url = $base . $url;
            }
        }
        if ($url !~ /^http:\/\//i) {
            $url = "http://" . $url;
        }
        push @result,$url;
    }
    return @result;
}

return 1;
