package NightGun::Gui::ContentView;
use Glib qw(TRUE FALSE);
use Encode::Guess;
use Gtk2;
use URI::Escape;
use NightGun;
use MyPlace::Encode;
use strict;
sub new {
    my $class=shift;
    my $type=shift;
    return bless {type=>$type,listener=>{}},$class;
}

sub signal_connect {
    my $self=shift;
    return $self->{notebook}->signal_connect(@_);
}

sub init_html {
    my $self=shift;
        eval 'use Gtk2::MozEmbed;';
        NightGun::warn("Gui::ContentView",$@) if($@);
        Gtk2::MozEmbed -> set_profile_path($ENV{ HOME } . "/.nightgun","NightGun");
        $self->{htmlview} = Gtk2::MozEmbed->new();
        $self->{htmlview}->set_chrome_mask("GTK_MOZ_EMBED_FLAG_ALLCHROME");# GTK_MOZ_EMBED_FLAG_TOOLBARON);
        $self->{notebook}->append_page($self->{htmlview},"htmlview");
        $self->_init_moz_signal($self->{htmlview});
        #$self->{htmlview}->load_url("about:blank");
        $self->{htmlview}->show_all();
        $self->{html_load}=1;
}

sub html_zoom {
    return undef;
#    my $self=shift;
#    my $zoom = shift;
#    return unless($zoom);
#    my $embd = $self->{htmlview};
#    my $moz = $embd->get_nsIWebBrowser();
#    NightGun::App::dump($self,[$embd,$moz],[qw/embd moz/]);
    return undef;
}
sub text_zoom {
    my $self=shift;
    my $zoom = shift;
    return unless($zoom);
    my $current_font = $self->{textview}->get_style()->font_desc;
    my $font_size = $current_font->get_size();
    return undef unless($font_size);
#    NightGun::App::message($self,"Current font size is $font_size, will zoom to " . ($font_size+$zoom*853) . ".");
    $font_size = $font_size*((10 + $zoom)/10);
    $current_font->set_size($font_size);
    $self->{textview}->modify_font($current_font);
    return 1,$current_font;
#    NightGun::App::dump("Gui::ContentView",[$current_font],["current_font"]);

    #$content->modify_font(Gtk2::Pango::FontDescription->from_string($options{font})) if($options{font});
    #$content->modify_text("normal",Gtk2::Gdk::Color->parse($options{forecolor})) if($options{forecolor});
    #$content->modify_base("normal",Gtk2::Gdk::Color->parse($options{backcolor})) if($options{backcolor});
    #$content->set_left_margin($options{leftmargin});
    #$content->set_right_margin($options{rightmargin});
    #$content->set_indent($options{lineindent});
    #$content->set_pixels_below_lines($options{linepadding}/2);
    #$content->set_pixels_above_lines($options{linepadding}/2);
    #$content->set_pixels_inside_wrap($options{linepadding});
}

sub _zoom {
    my $self=shift;
    my $current_view = $self->get_current_view();
    if($current_view eq "textview") {
        return undef unless($self->{textview});
        return $self->text_zoom(@_);
    }
    else {
        return undef unless($self->{htmlview});
        return $self->html_zoom(@_);
    }
}

sub zoom_out {
    &_zoom(@_,-1);
}

sub zoom_in {
    &_zoom(@_,+1);
}

sub go_back {
    my $self = shift;
    my $current_view = $self->get_current_view();
    if($current_view eq "textview") {
        return undef;
    }
    $self->{htmlview}->go_back() if($self->{htmlview});
}
sub go_forward {
    my $self = shift;
    my $current_view = $self->get_current_view();
    if($current_view eq "textview") {
        return undef;
    }
    $self->{htmlview}->go_forward() if($self->{htmlview});
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
    return $self->{listener}{$name}(@arg) if($self->{listener}{$name});
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

sub GtkWidget {
    my $self=shift;
    return $self->{widget};
}
sub get_state {
    my $self=shift;
    $self->{textview}->place_cursor_onscreen;
    my $buffer = $self->{textview}->get_buffer;
    my $mark = $buffer->get_mark('insert');
    my $iter = $buffer->get_iter_at_mark($mark);
    return $iter->get_offset();
}
sub set_state {
    my ($self,$offset) = @_;
    my $buffer = $self->{textview}->get_buffer;
    my $iter = $buffer->get_iter_at_offset($offset);
    my $mark = $buffer->get_mark('insert');
    $buffer->place_cursor($iter);
    $self->{textview}->scroll_to_mark($mark,0.0,1,0.0,0.0);
}

sub encoding_changed {
    my $self=shift;
    if(defined $self->{text}) {
        $nightgun_global->{GUI}->content_begin_set;
        my @state = $self->get_state;
        $self->content_set_stream($self->{text});
#        $nightgun_global->{GUI}->content_progress_set;
#        $nightgun_global->{GUI}->update;
#        $nightgun_global->{GUI}->content_progress_set;
        $self->set_state(@state);
#        $nightgun_global->{GUI}->content_progress_set;
#        $nightgun_global->{GUI}->content_end_set;
    }
}
sub decode_text {
    my $self = shift;
    my $text = shift;
    return $text unless($text);
    my $codename = shift || $nightgun_global->{GUI}->{options}{encoding};
    my $enc;
    if($codename eq "auto") {
        $enc = MyPlace::Encode::guess_encoding($text,1,'big5','utf8');
    }
    else {
        $enc = Encode::find_encoding($codename);
    }
    return $enc->decode($text) if(ref $enc);
}

sub set_uri {
    my($self,$data) = @_;
    $self->{text}=undef;
    $self->{textview}->get_buffer->set_text("") if($self->{textview});#set_text($text);
    $data = "file:///$data" if($data =~ /^\// and $data !~ /^file:/);
    NightGun::message("Gui::ContentView","set_uri :$data");
             $self->init_html unless($self->{html_load});
            $self->{htmlview}->load_url($data);
            $self->{htmlview}->show_all();
            $self->{notebook}->set_current_page(1);
            $self->{notebook}->set_current_page(0);
            $self->{notebook}->set_current_page(1);
    return 1;
}

sub get_current_view {
    my $self=shift;
    if($self->{notebook}->get_current_page() == 0) {
        return "textview";
    }
    else {
        return "htmlview";
    }
}

sub set_stream {
    my($self,$data) = @_;
    $self->{htmlview}->load_url("about:blank") if($self->{htmlview});
            $self->{text}=$data;
            my $text = $self->decode_text($self->{text});
            $self->{textview}->get_buffer->set_text($text);
            $self->{textview}->show_all();
            $self->{notebook}->set_current_page(0);
            eval {$self->{notebook}->set_current_page(1)};
            $self->{notebook}->set_current_page(0);
            return 1;
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
#    $nightgun_global->{GUI}->update(); 
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
    our $AUTOLOAD =~ /^.*::([^:]+)$/;
    return if($1 eq "DESTROY");
    my $result;
    my $method=$1;
    my @args = @_;
    if($self->{textview} and $self->{textview}->can($method)) {
        eval  {
            $result = $self->{textview}->$method(@args);
        };
    }
    elsif($self->{htmlview} and $self->{htmlview}->can($method)) {
        eval  {
            $result = $self->{htmlview}->$method(@args);
        };
    }
    elsif($self->{notebook} and $self->{notebook}->can($method)) {
        eval  {
            $result = $self->{notebook}->$method(@args);
        };
    }
    else {
        NightGun::App::error("Gui::ContentView","Unimplemented function called:$method(" . join(", ",@args) . ")");
        return undef;
    }
    #print STDERR "$!\n" if($!);
    return $result;
}
1;
