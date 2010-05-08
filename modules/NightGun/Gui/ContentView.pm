package NightGun::Gui::ContentView;
use Glib qw(TRUE FALSE);
use Encode;
use Encode::Guess;
use Gtk2;
use NightGun;

sub new {
    my $class=shift;
    my $type=shift;
    return bless {type=>$type,listener=>{}},$class;
}

sub init_html {
    my $self=shift;
        eval 'use Gtk2::MozEmbed;use URI::Escape;';
        print STDERR "Warning: $@\n" if($@);
        Gtk2::MozEmbed -> set_profile_path($ENV{ HOME } . "/.nightgun","NightGun");
        $self->{htmlview} = Gtk2::MozEmbed->new();
        $self->{notebook}->append_page($self->{htmlview},"htmlview");
        $self->_init_moz_signal($self->{htmlview});
        #$self->{htmlview}->load_url("about:blank");
        $self->{htmlview}->show_all();
        $self->{html_load}=1;
}
sub attatch {
    my $self=shift;
    my $notebook = shift;
    my $textview = shift;
    $self->{notebook}=$notebook;
    $self->{textview}=$textview;
    if($self->{type} and $self->{type} eq "MozEmbed") {
        $self->{html}=1;
    }
    else {
        $self->{html}=0;
    }
    $self->{notebook}->set_current_page(0);
}

sub _init_moz_signal {
    my ($self,$w) = @_;
    $w->signal_connect(link_message=>sub {$self->_link_message(@_);});
    $w->signal_connect(location=>sub {$self->_location(@_);});
}

sub _link_message {
    my ($self,$emb)=@_;
    if($self->{listener}{status_changed}) {
        $self->{listener}{status_changed}(decode('utf8',$emb->get_link_message));
    }
}

sub _location {
    my ($self,$emb)=@_;
    if($self->{listener}{location}) {
        $self->{listener}{location}(decode('utf8',uri_unescape($emb->get_location)));
    }
}

sub GtkWidget {
    my $self=shift;
    return $self->{widget};
}
sub get_state {
    my $self=shift;
    return $self->{textview}->get_visible_rect->values;
}
sub set_state {
    my $self = shift;
    my($x,$y)=@_;
    my $iter = $self->{textview}->get_iter_at_location($x,$y) ;
    $self->{textview}->scroll_to_iter($iter,0,1,0,0);
}

sub encoding_changed {
    my $self=shift;
    if(defined $self->{text}) {
        $nightgun_global->{GUI}->content_begin_set;
        my @state = $self->get_state;
        $self->set_content({text=>$self->{text}});
        $nightgun_global->{GUI}->content_progress_set;
        $nightgun_global->{GUI}->update;
        $nightgun_global->{GUI}->content_progress_set;
        $self->set_state(@state);
        $nightgun_global->{GUI}->content_progress_set;
        $nightgun_global->{GUI}->content_end_set;
    }
}

sub decode_text {
    my $self = shift;
    my $text = shift;
    my $codename = shift || $nightgun_global->{GUI}->{options}{encoding};
    my $enc;
    if($codename eq "auto") {
        $enc = guest_encoding($text,'utf8','big5');
        if(ref $enc) {
            $enc = $enc->name;
        }
        else {
            $enc = "gb2312";
        }
    }
    else {
        $enc = $codename;
    }
    print STDERR "TEXT ENCODING:$enc\n";
    return decode($enc,$text);
}

sub set_content {
    my ($self,$store)=@_;
    $self->{text}=undef;
#    $self->{notebook}->set_sensitive(0);
    if($self->{html}) {
        if($store->{url}) {
            $self->init_html unless($self->{html_load});
            $self->{htmlview}->load_url($store->{url});
            $self->{htmlview}->show_all();
            $self->{notebook}->set_current_page(1);
            $self->{notebook}->set_current_page(0);
            $self->{notebook}->set_current_page(1);
        }
        elsif($store->{default_entry}) {
            print STDERR "Load default entry " . $store->{default_entry} . "\n";
            $nightgun_global->{StoreLoader}($store->{default_entry}); 
        }
        else {
            $self->{text}=$store->{text};
            my $text = $self->decode_text($self->{text});
#            $text = MyPlace::Encode::decode($text) if($text);
            #$text =~ s/\n\s*\n/\n/gm;
            $self->{textview}->get_buffer->set_text($text);
            $self->{textview}->show_all();
            $self->{notebook}->set_current_page(0);
            eval {$self->{notebook}->set_current_page(1);};
            $self->{notebook}->set_current_page(0);
        }
    }
    else {
            $self->{text}=$store->{text};
            my $text = $self->decode_text($store->{text});
            #$text = MyPlace::Encode::decode($store->{text});
            $self->{textview}->get_buffer->set_text($text) ;
    }
    $nightgun_global->{GUI}->update(); 
#    $self->{notebook}->set_sensitive(1);
}

sub get_content {
        my $self=shift;
        return unless($self->{textview});
        my $buffer = $self->{textview}->get_buffer;
        return unless($buffer);
        return $buffer->get_text($buffer->get_start_iter,$buffer->get_end_iter,0);
}
sub AUTOLOAD {
    my $self=shift;
#    print STDERR "$AUTOLOAD\n";
    $AUTOLOAD =~ /^.*::([^:]+)$/;
    return if($1 eq "DESTROY");
    my $result;
    my $method=$1;
    my @args = @_;
    eval  {
        $result = $self->{textview}->$method(@args);
    };
    #print STDERR "$!\n" if($!);
    return $result;
}
1;
