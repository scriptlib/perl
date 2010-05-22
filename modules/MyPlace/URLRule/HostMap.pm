#!/usr/bin/perl -w
package MyPlace::URLRule::HostMap;
use strict;
use warnings;
require MyPlace::URLRule::HostMapData;
our %HOST_MAP;
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
    @EXPORT         = qw();
    @EXPORT_OK      = qw(%HOST_MAP &get_task &valid_hostname &add_host &get_hosts);
}


sub valid_hostname {
    return undef unless($_[0] and $HOST_MAP{$_[0]});
    return 1;
}

sub get_hosts {
    return keys %HOST_MAP;
}

sub add_host {
    my($name,$url,$level)=@_;
    $level = 0 unless($level);
    $HOST_MAP{$name}->{url}=$url;
    $HOST_MAP{$name}->{level}=$level;
    return $HOST_MAP{$name};
}


sub get_task {
    my ($host,$id,$maps)=@_;
    $maps = \%HOST_MAP unless(ref $maps);
    my $url = $maps->{$host}->{url};
    my $level = $maps->{$host}->{level};
    my ($id_name,@id_text) = split(/\s*:\s*/,$id);
    $url =~ s/###(?:ID|NAME])###/$id_name/g;
    my $index = 0;
    foreach(@id_text) {
        $index++;
        $url =~ s/###TEXT$index###/$_/g;
    }
    return $url,$level;
}


1;
