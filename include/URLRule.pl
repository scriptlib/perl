#!/usr/bin/perl -w

package URLRule;

do `plinclude URL`;

sub rule_dir(){return "/share/perl/urlrule";};
sub get_rule($$) {
    my $url=shift;
    my $level=shift;
    $level=0 unless($level);
    my $domain=URL::domain($url);
    return rule_dir() . "\/$level\/" . $domain;
}
