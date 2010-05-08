#!/usr/bin/perl -w
package DayShooter::MozClient;
use strict;
use warnings;
use Gtk2;
use Gtk2::GladeXML;
use Gtk2::MozEmbed;
use MyPlace::Gtk2;
use File::Spec;

=comment
my $UI = <<EOF;
<interface>
<object class="GtkWindow" id="window">
    <property name="width_request">600</property>
    <property name="height_request">480</property>
    <child>
        <object class="GtkVBox" id="vbox">
            <child>
                <object class="GtkHBox" id="addressBox">
                    <child>
                        <object class="GtkComboBoxEntry" id="address">
                            <child internal-child="entry">
                                <object class="GtkEntry" id="addressEntry">
                                    <signal name="activate" handler="address_text_changed"/>
                                </object>
                            </child>
                        </object>
                    </child>
                    <child>
                        <object class="GtkButton" id="addressButton">
                            <property name="label">gtk-ok</property>
                            <property name="use-stock">TRUE</property>
                            <signal name="clicked" handler="address_text_changed"/>
                        </object>
                        <packing>
                            <property name="expand">FALSE</property>
                        </packing>
                    </child>
                </object>
                <packing>
                    <property name="expand">FALSE</property>
                </packing>
            </child>
        </object>
    </child>
</object>
</interface>

EOF
=cut

sub new {
    my $class = shift;
    my $self = bless {@_},$class;
    $self->init;
    return $self;
}

sub init {
    my $self = shift;
    Gtk2->init();
    Gtk2::MozEmbed->set_profile_path(File::Spec->catfile($ENV{HOME} ,"/.dayshooter/mozclient"),"DayShooter");
    
    my $glade = Gtk2::GladeXML->new(File::Spec->catfile($self->{appdir},"MozClient.glade")) or die("$@\n");
    $glade->signal_autoconnect_from_package($self);
    foreach my $widget (qw/
                window
                menubar
                toolbar
                addressBox
                addressEntry
                statusbar
                contentLeft
                contentPaned
        /) {
        $self->{$widget} = $glade->get_widget($widget);
    }

=builder
    my $builder = Gtk2::Builder->new();
    $builder->add_from_file(File::Spec->catfile($self->{appdir},"MozClient.glade")) or die("$@\n");
    $builder->connect_signals($self,$self);
    $self->{window} = $builder->get_object('window');
    $self->{window}->signal_connect('delete_event'=>,sub { Gtk2->main_quit();return 0});
    $self->{vbox} = $builder->get_object('vbox');
    $self->{addressBox} = $builder->get_object('addressBox');
    $self->{address} = $builder->get_object('address');
    $self->{addressEntry} = $builder->get_object('addressEntry');
    $self->{addressButton} = $builder->get_object('addressButton');
=cut    
    $self->{moz} = Gtk2::MozEmbed->new();
    $self->{contentPaned}->add2($self->{moz});
   # $self->{window}->maximize;

   foreach my $event (qw/
            link_message
            js_status
            location
            title
            progress
            net_state
            net_start
            net_stop
            new_window
            visibility
            destroy_browser
            open_uri
            dom_key_down
            dom_key_up
            dom_key_press
            dom_mouse_down
            dom_mouse_up
            dom_mouse_click
            dom_mouse_dbl_click
            dom_mouse_over
            dom_mouse_out
            /) {
        $self->{moz}->signal_connect($event,sub {return $self->on_events($event,@_)});
   }
}

sub on_window_delete {
}
sub on_window_destroy {
    Gtk2::main_quit();
    return 1;
}

sub jump {
    my $self = shift;
    my $uri = $self->{addressEntry}->get_text();
    return $self->open_uri($uri);
}

sub go_back {
    return $_[0]->{moz}->go_back();
}

sub go_forward {
    return $_[0]->{moz}->go_forward();
}

sub refresh {
    return $_[0]->{moz}->reload('GTK_MOZ_EMBED_FLAG_RELOADNORMAL');
}

sub on_events {
   # print STDERR "$_\t" foreach(@_);
    my($self,$name,$emb,@args) = @_;
    if($name eq 'js_status') {
        @args = ($emb->get_js_status);
        $self->{statusbar}->push(0,@args);
    }
    elsif($name eq 'link_message') {
        @args = ($emb->get_link_message);
        $self->{statusbar}->push(0,@args);
    }
    elsif($name eq 'location') {
        @args = ($emb->get_location);	
        $self->{addressEntry}->set_text(@args);
    }
    elsif($name eq 'title') {
        @args = ($emb->get_title);
        $self->{window}->set_title($emb->get_title);
    }
    elsif($name eq 'new_window') {
        return $emb;
    }

    if($self->{server}) {
        return $self->{server}->callback($self,$name,@args);
    }
    elsif($self->{piper}) {
        return $self->talking($name,@args);
    }
    return undef;
}

sub run {
    my $self = shift;
    my %args = @_;
    $self->{window}->show_all;
    if($args{uri}) {
        $self->open_uri($args{uri});
    }
    elsif($args{data}) {
        $self->set_data($args{data});
    }
    return Gtk2->main();
}

sub open_uri {
    my $self = shift;
    $self->{moz}->stop_load;
    $self->{moz}->load_url(@_);
    return 1;
}

sub set_data {
    my $self = shift;
    my ($data,$base_uri,$mime_type) = @_;
    #$self->{moz}->open_stream($base_uri || "",$mime_type || "text/html");
    #$self->{moz}->append_data($data);
    #$self->{moz}->close_stream;
    $self->{moz}->render_data($data,$base_uri || "about:blank",$mime_type || "text/html");
    $self->{addressEntry}->set_text($base_uri || "about:blank");
    return 1;
}

sub talking {
    my ($self,$name,@args) = @_;
    open FI,"-|",$self->{piper},$name,@args;
    my @msgs = <FI>;
    close FI;
    if(@msgs) {
        my $action = shift @msgs;
        chomp($action);
        if($action eq 'open_uri') {
            $self->open_uri(@msgs);
        }
        else {
            my $base_uri = shift @msgs;chomp($base_uri);
            my $mime_type = shift @msgs;chomp($mime_type);
            $self->set_data(join("",@msgs),$base_uri,$mime_type);
        }
        return 1;
    }
    return undef;
}
1;
