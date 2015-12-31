#!/usr/bin/perl -w
package MyPlace::String;
BEGIN {
    use Exporter ();
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw(&strnum);
}

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
return 1;
