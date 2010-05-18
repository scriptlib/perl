package NightGun::Gui::ContentView;
use Glib qw(TRUE FALSE);
use Encode::Guess;
use Gtk2;
use NightGun;
use MyPlace::Encode;
use strict;
our @VIEWER_CLASS = qw/TextView HTMLView/;
#use NightGun::Gui::TextView;

sub _init_viewer {
    my @result;
    my $idx=-1;
    foreach my $class (map "NightGun::Gui::$_",@VIEWER_CLASS) {
	eval "use $class;";
	if($@){
	    NightGun::error("Gui::ContentView","Error: using $class");
	    NightGun::error("Gui::ContentView",$@);
	    next;
	}
        my $viewer = $class->new();
        $idx++;
        $viewer->{id}=$idx;
        push @result,$viewer;
    }
    return @result;
}


sub talk {
    my $self = shift;
    my $event_name = shift;
    my @args = @_;
    $self->{listener}->{$event_name}(@args) if($self->{listener}{$event_name});
}

sub new {
    my $class=shift;
    my $notebook= Gtk2::Notebook->new();
    $notebook->set_show_tabs(FALSE);
    $notebook->show();
    my @viewers = _init_viewer();
    my $self = bless {notebook=>$notebook,viewers=>\@viewers,listener=>{},widget=>$notebook},$class;
    foreach(@viewers) {
        $_->{parent} = $_;
        $self->{notebook}->append_page($_->{widget},$_->{name});
    }
    $self->{current_view} = $viewers[0];
    $self->{notebook}->set_current_page(0);
    $self->{current_view}{widget}->show();
    $self->{current_view}{viewer}->show();
    return $self;
}

sub _zoom {
    my $self=shift;
    $self->{current_view}->zoom(@_);
}

sub zoom_out {
    &_zoom(@_,-1);
}

sub zoom_in {
    &_zoom(@_,+1);
}

sub go_back {
    my $self = shift;
    $self->{current_view}->go_back(@_);
}
sub go_forward {
    my $self = shift;
    $self->{current_view}->go_forward(@_);
}

sub get_state {
    my $self=shift;
    $self->{current_view}->get_state(@_);
}
sub set_state {
    my $self=shift;
    $self->{current_view}->set_state(@_);
}

sub encoding_changed {
    my $self=shift;
    $self->{current_view}->encoding_changed(@_);
}

sub set_uri {
    my $self = shift;
    foreach(@{$self->{viewers}}) {
        my $r = $_->set_uri(@_);
        if($r and $_->{id} != $self->{current_view}->{id}) {
            $self->{current_view}->stop();
            $self->{current_view}=$_;
            $self->{current_view}->show();
            $self->{notebook}->set_current_page($_->{id});
            return $r;
        }
    }
}
sub set_stream {
    my $self = shift;
    foreach(@{$self->{viewers}}) {
        my $r = $_->set_stream(@_);
        if($r and $_->{id} != $self->{current_view}->{id}) {
            $self->{current_view}->stop();
            $self->{current_view}=$_;
            $self->{current_view}->show();
            $self->{notebook}->set_current_page($_->{id});
            return $r;
        }
    }
}

sub set_content {
    my $self = shift;
    foreach(@{$self->{viewers}}) {
        my $r = $_->set_content(@_);
        if($r) {
            $self->{current_view}->stop();
            $self->{notebook}->set_current_page($_->{id});
            $self->{notebook}->set_current_page($self->{current_view}{id});
            $self->{current_view}=$_;
            $self->{notebook}->set_current_page($_->{id});
            $self->{current_view}->show();
            return $r;
        }
    }
}

sub get_content {
        my $self=shift;
        $self->{current_view}->get_content();

}

sub AUTOLOAD {
    my $self=shift;
    our $AUTOLOAD =~ /^.*::([^:]+)$/;
#    NightGun::App::warn("Gui::ContentView","AUTOLOAD: $AUTOLOAD");
    return if($1 eq "DESTROY");
    my $result;
    my $method=$1;
    my @args = @_;
#    if($self->{current_view} and $self->{current_view}->can($method)) {
        eval  {
            $result = $self->{current_view}->$method(@args);
        };
#    }
#    elsif($self->{notebook} and $self->{notebook}->can($method)) {
#        eval  {
#            $result = $self->{notebook}->$method(@args);
#        };
#    }
    if($!) {
#        NightGun::App::error("Gui::ContentView","$!");
        return undef;
    }
    #print STDERR "$!\n" if($!);
    return $result;
}
1;
