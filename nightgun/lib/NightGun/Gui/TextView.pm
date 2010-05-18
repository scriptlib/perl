package NightGun::Gui::TextView;
use base qw/NightGun::Gui::View/;
use Glib qw(TRUE FALSE);
use Gtk2;

use Encode::Guess;

use MyPlace::Encode;
use NightGun;

use strict;
sub new {
    my $self = NightGun::Gui::View::new(@_);
    
    my $sw = Gtk2::ScrolledWindow->new();
    $sw->set_policy('GTK_POLICY_AUTOMATIC','GTK_POLICY_AUTOMATIC');

    my $textview = Gtk2::TextView->new();
    $textview->set_editable(TRUE);
#    $textview->set_wrap_mode('GTK_WRAP_WORD');
    $textview->set_cursor_visible(TRUE);
    $sw->add($textview);
    $textview->show();
    $sw->show_all();

    $self->{name}="TextView";
    $self->{widget}=$sw;
    $self->{viewer}=$textview;
    return $self;
}

sub zoom {
    my $self=shift;
    my $zoom = shift;
    return unless($zoom);
    my $current_font = $self->{viewer}->get_style()->font_desc;
    my $font_size = $current_font->get_size();
    return undef unless($font_size);
    $font_size = $font_size*((10 + $zoom)/10);
    $current_font->set_size($font_size);
    $self->{viewer}->modify_font($current_font);
    return 1,$current_font;
}

sub zoom_out {
    &zoom(@_,-1);
}

sub zoom_in {
    &zoom(@_,+1);
}

sub go_back {
    return undef;
}

sub go_forward {
    return undef;
}

sub stop {
    return 1;
}
sub get_state {
    my $self=shift;
    $self->{viewer}->place_cursor_onscreen;
    my $buffer = $self->{viewer}->get_buffer;
    my $mark = $buffer->get_mark('insert');
    my $iter = $buffer->get_iter_at_mark($mark);
    return $iter->get_offset();
}
sub set_state {
    my ($self,$offset) = @_;
    my $buffer = $self->{viewer}->get_buffer;
    my $iter = $buffer->get_iter_at_offset($offset);
    my $mark = $buffer->get_mark('insert');
    $buffer->place_cursor($iter);
    $self->{viewer}->scroll_to_mark($mark,0.0,1,0.0,0.0);
}

sub encoding_changed {
    my $self=shift;
        my @state = $self->get_state;
        $self->content_set_stream($self->{text});
        $self->set_state(@state);
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
sub stop {
    my $self = shift;
    $self->{viewer}->get_buffer->set_text('');
}
sub set_uri {
    return undef;
}

sub set_stream {
    my($self,$data) = @_;
            my $text = $self->decode_text($data);
            $self->{viewer}->get_buffer->set_text($text);
            $self->{viewer}->show_all();
            return 1;
}

sub set_content {
    return undef;
}

sub get_content {
        my $self=shift;
        my $buffer = $self->{viewer}->get_buffer;
        return unless($buffer);
        return $buffer->get_text($buffer->get_start_iter,$buffer->get_end_iter,0);
}

sub AUTOLOAD {
    my $self=shift;
    our $AUTOLOAD =~ /^.*::([^:]+)$/;
#    NightGun::App::warn("Gui::TextView","AUTOLOAD: $AUTOLOAD");
    return if($1 eq "DESTROY");
    my $result;
    my $method=$1;
    my @args = @_;
    if($self->{viewer} and $self->{viewer}->can($method)) {
        eval  {
            $result = $self->{viewer}->$method(@args);
        };
    }
    elsif($self->{widget} and $self->{widget}->can($method)) {
        eval  {
            $result = $self->{widget}->$method(@args);
        };
    }
    else {
        NightGun::App::error("Gui::TextView","Unimplemented function called:$method(" . join(", ",@args) . ")");
        return undef;
    }
    #print STDERR "$!\n" if($!);
    return $result;
}
1;
