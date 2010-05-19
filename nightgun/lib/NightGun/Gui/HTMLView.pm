package NightGun::Gui::HTMLView;
use base qw/NightGun::Gui::View/;
use Glib qw(TRUE FALSE);
use Gtk2::MozEmbed;

use Encode::Guess;
use Gtk2;
use URI::Escape;
use NightGun;
use MyPlace::Encode;
use strict;
sub new {
    my $self = NightGun::Gui::View::new(@_);

    Gtk2::MozEmbed -> set_profile_path($ENV{ HOME } . "/.nightgun","NightGun");
    my $moz = Gtk2::MozEmbed->new();
    $moz->set_chrome_mask("GTK_MOZ_EMBED_FLAG_ALLCHROME");# GTK_MOZ_EMBED_FLAG_TOOLBARON);
    $self->{name}="HTMLView";
    $self->{widget}=$moz;
    $self->{viewer}=$moz;
    return $self;
}
sub stop {
    my $self=shift;
    $self->{viewer}->load_url("about:blank");
}
sub _zoom {
    my $self=shift;
    my $current_view = $self->get_current_view();
    if($current_view eq "textview") {
        return undef unless($self->{textview});
        return $self->text_zoom(@_);
    }
    else {
        return undef unless($self->{viewer});
        return $self->html_zoom(@_);
    }
}

sub zoom_out {
    return undef;
}

sub zoom_in {
    return undef;
}

sub go_back {
    my $self = shift;
    $self->{viewer}->go_back();
}
sub go_forward {
    my $self = shift;
    $self->{viewer}->go_forward();
}

sub _moz_event {
    my ($self,$name,$emb,@arg) = @_;
#    print STDERR "MozEvent:",$name,$emb,@arg,"\n";
    if($name eq 'js_status') {
        $name = "status_changed";
        @arg = ($emb->get_js_status());
    }
    elsif($name eq 'link_message') {
        $name = "status_changed";
        @arg = ($emb->get_link_message);
    }
    elsif($name eq 'location') {
        @arg = ($emb->get_location);    
    }
    elsif($name eq 'open_url') {
        return 1;
    }
    elsif($name eq 'destory_browser') {
        return 1;
    }
    elsif($name eq 'title') {
        @arg = ($emb->get_title);
    }
    elsif($name eq 'new_window') {
        return $emb;
    }
    elsif($name eq 'net_stop') {
        $name = 'progress';
        @arg = qw/1 1/;
    }
    return $self->{parent}->{talk}($name,@arg);
    return undef;
}
sub _init_moz_signal {
    my ($self,$w) = @_;
    no strict;
    foreach my $sig qw/
        link_message js_status location title progress
        new_window open_uri destroy_browser net_stop
        / {
                #dom_key_down dom_key_up dom_key_press
                #dom_mouse_down dom_mouse_up dom_mouse_click dom_mouse_dbl_click dom_mouse_out
        $w->signal_connect($sig=>sub {$self->_moz_event($sig,@_);});
    }
}

sub get_state {
    return undef;
}
sub set_state {
    return undef;
}
sub encoding_changed {
}


sub set_uri {
    my($self,$data) = @_;
    $data = "file:///$data" if($data =~ /^\// and $data !~ /^file:/);
    NightGun::message("Gui::HTMLView","set_uri :$data");
            $self->{viewer}->load_url($data);
    return 1;
}

sub set_stream {
    return undef;
}

sub set_content {
    return &set_uri(@_);
}

sub get_content {
    return undef;
}

sub AUTOLOAD {
    my $self=shift;
    our $AUTOLOAD =~ /^.*::([^:]+)$/;
    NightGun::App::warn("Gui::HTMLView","AUTOLOAD: $AUTOLOAD");
    return if($1 eq "DESTROY");
    my $result;
    my $method=$1;
    my @args = @_;
    eval  {
        $result = $self->{viewer}->$method(@args);
    };
    return $result;
}
1;
