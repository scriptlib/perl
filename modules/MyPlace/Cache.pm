#!/usr/bin/perl -w
package MyPlace::Cache;
no warnings;
use constant {
    DEFAULT_APP => "default",
    DEFAULT_DB => "/tmp/myplace_cache",
    KEY_MAX_LENGTH => "256",
    EXPIRED => 3600*12,
};

sub new {
    my ($class,$app,$db) = @_;
    $class = "MyPlace::Cache" unless($class);
    $app = DEFAULT_APP unless($app);
    $db = DEFAULT_DB unless($db);
    for($db,"$db/$app") {
        unless(-d $_) {
            return undef unless(mkdir $_);
        }
    }
    return bless {node=>"$db/$app"},$class;
}

sub load {
    my ($self,$key) = @_;
    $key =~ s/[\/\\]/#/g;
    $key = substr($key,0,KEY_MAX_LENGTH-1);
    return () unless(-f $self->{node} . "/" . $key);
    open FI,"<",$self->{node} . "/" . $key or return ();
    my $ts = <FI>;
    if($ts =~ /^timestamp:(\d+)/) {
        $ts = $1;
        if((time - $ts)>EXPIRED) {
            close FI;
            return ();
        }
        my @values = <FI>;
        close FI;
        #warn "MyPlace::Cache::",$self->{node},"->load $key \n";
        return @values;
    }
    else {
        close FI;
        return ();
    }
}

sub save {
    my ($self,$key,@value) = @_;
    $key =~ s/[\/\\]/#/g;
    $key = substr($key,0,KEY_MAX_LENGTH-1);
    open FO,">",$self->{node} . "/" . $key or return @value;
    print FO "timestamp:" . time . "\n";
    print FO @value;
    close FO;
    #warn "MyPlace::Cache::",$self->{node},"->save $key \n";
    return @value;
}

1;
