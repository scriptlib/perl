#!/usr/bin/perl -w
package testmoz;

unless(@ARGV) {
    require DayShooter::MozClient;
    my $client = DayShooter::MozClient->new(piper=>'./testmoz.pl',appdir=>'../share/dayshooter');
#    $client->run(data=>'<html><body>hello,world</body></html>');
    $client->run(uri=>"http://testmoz/myplace");
}
else {
    my ($action,$arg) = @ARGV;
    print STDERR join("##",@ARGV),"\n";
    if($action && $action eq 'open_uri' && $arg && $arg =~ /^http:\/\/testmoz\/myplace(.*)$/) {
        $arg = $1;
        print "set_data\nhttp://testmoz\/myplace\ntext/html\n";
        $arg =~ s/\//:/g;
        open FI,"-|",'/myplace/workspace/wiki/cgi-bin/linux/myplace.pl',$arg;
        print <FI>;
        close FI;
    }
}




