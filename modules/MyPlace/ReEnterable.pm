package MyPlace::ReEnterable;
use Data::Dumper;
use strict;

sub new {
    my $class = CORE::shift;
    my $pkg = CORE::shift || 'main';
    return bless {stack=>[],package=>$pkg},$class;
}

sub push {
    my $self = CORE::shift;
    CORE::push @{$self->{stack}},[@_];
}

sub unshift {
    my $self = CORE::shift;
    CORE::unshift @{$self->{stack}},[@_];
}

sub pop {
    my $self = CORE::shift;
    return undef unless($self->{stack});
    return undef unless(@{$self->{stack}});
    return @{CORE::pop(@{$self->{stack}})};
}

sub shift {
    my $self = CORE::shift;
    return undef unless($self->{stack});
    return undef unless(@{$self->{stack}});
    return @{CORE::shift(@{$self->{stack}})};
}

sub peek {
    my $self = CORE::shift;
    my $length = $self->length;
    return undef unless($length);
    return @{$self->{stack}->[0]};
}

sub setAll {
    my $self = CORE::shift;
    $self->{stack} = [@_];
}

sub getAll {
    my $self = CORE::shift;
    return @{$self->{stack}};
}

sub isEmpty {
    my $self = CORE::shift;
    return not scalar(@{$self->{stack}});
}
sub length {
    my $self = CORE::shift;
    return scalar(@{$self->{stack}});
}
sub run {
    no strict 'refs';
    my $self = CORE::shift;
    my $verbose = CORE::shift;
    return undef unless(@{$self->{stack}});
    my @this = $self->pop();#popStack();
    $self->{lastStack} = [@this];
    if(@this) {
        my $cwd = CORE::shift @this || "";
        if($cwd) {
            mkdir $cwd unless(-d $cwd);
            chdir $cwd or warn("$!\n");
        }
        my $func = CORE::shift @this;
        if($func) {
            print STDERR "$cwd> $func(" . join(",",@this) . ")\n" if($verbose);
            $func = $self->{package} . "::$func";
            $func->(@this);
        }
    }
    return 1;
}

sub loop {
    my $self = CORE::shift;
    my $verbose = CORE::shift;
    while($self->run($verbose)) {
        print STDERR $self->length," tasks remained\n" if($verbose);
    }
    return 1;
}

sub setState {
    my ($self,$key,$value) = @_;
    $self->{state}->{$key} = $value;
    return $value;
}

sub getState {
    my ($self,$key) = @_;
    return $self->{state}->{$key};
}

sub loadFromFile {
    my $self = CORE::shift;
    my $file = CORE::shift;
    return undef unless(-f $file);
    local $Data::Dumper::Purity = 1;
    my ($Resume,$State);
    open FI,"<",$file or return undef;
    my $text = join("",<FI>);
    close FI;
    eval $text;
    return undef unless($Resume);
    $self->{stack}=$Resume;
    $self->{state}=$State;
}

sub saveToFile {
    my $self = CORE::shift;
    my $file = CORE::shift;
    local $Data::Dumper::Purity = 1;
    my $Resume = $self->{stack};
    open FO,">",$file;
    print FO Data::Dumper->Dump([$Resume,$self->{state}],["Resume","State"]);
    close FO;
}

1;
