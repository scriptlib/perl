#!/usr/bin/perl -w
package NightGun::Gui;
use strict;
use warnings;
use NightGun::App;
use NightGun::Gui::ContentView;
use NightGun::Encode;
use Gtk2::Gdk::Keysyms;
use Glib qw/TRUE FALSE/;

BEGIN {
    if(NightGun::App::GUI eq 'GNOME') {
        eval '
            use Gnome2;
            Gnome2::Program->init (NightGun::App::NAME,NightGun::App::VERSION);
        ';
    }
    else {
        eval '
            use Gtk2;
            Gtk2->init;
        ';
    }
}
use MyPlace::Gtk2;

use constant WIDGETS_MAP => (
    'win_main_window',
    'menu',
    'menu_show_list',
    'menu_show_panel',
    'cbo_hot_list',
    'entry_hot_list_entry',
    'hp_content_paned',
    'sw_left_window',
    'tv_left',
#    'nb_content_notebook',
#    'sw_content_window',
#    'txt_content_textview',
    'hbox_status_box',
    'sbar_status_bar',
    'hb_hotlist_box',
    
    'dlg_options_window',
    'btn_options_font',
    'chk_options_word_wrap',
    'btn_options_fore_color',
    'btn_options_back_color',
    'spin_options_left_margin',
    'spin_options_right_margin',
    'spin_options_line_indent',
    'spin_options_line_padding',
    'cbo_encoding_list',
    'cbo_encoding_text',
    'btn_options_ok',
    'btn_options_cancel',
    'btn_options_apply',

    'pbar_progress_bar',
    
    'dlg_about_window'

);
our %WIDGETS_MAP =  map {my $n=$_;$n =~ s/^[^_]+_//;($n=>$_)} (WIDGETS_MAP);

#NightGun::App::dump(\%WIDGETS_MAP);



sub new {
    my ($class,$glade_file) = @_;
    my $self = bless {
        glade_file => $glade_file,
        events => {
            main_destory=>undef,
            main_select_file=>undef,
            main_select_dir=>undef,
            file_list_selected=>undef,
            hot_list_changed=>undef,
            content_scrolled=>undef,
            location_changed=>undef,
            encoding_changed=>undef,
            },
        },$class;
    $self->init;
    return $self;
}

sub init {
    my ($self,$glade_file) = @_;
    $glade_file = $self->{glade_file} unless($glade_file);
    if(-f $glade_file) {
#        use Gtk2::Builder;
        $self->{glade_file}=$glade_file;
        $self->{glade}=Gtk2::Builder->new();
        $self->{glade}->add_from_file($glade_file);
        $self->{glade}->connect_signals(undef,$self);

        foreach(keys %WIDGETS_MAP) {
            $self->{$_} = 
                $self->{glade}->get_object($WIDGETS_MAP{$_});
        }

        $self->{encoding_list} = Gtk2::ComboBoxEntry->new_text();
        $self->{encoding_list}->show();
        Gtk2::Box::pack_end($self->{status_box},$self->{encoding_list},0,0,0);
        $self->{hot_list} = Gtk2::ComboBoxEntry->new_text();
        $self->{hot_list}->show();
        Gtk2::Box::pack_start($self->{hotlist_box},$self->{hot_list},1,1,0);

        $self->{encoding_text} = $self->{encoding_list}->get_child();
        $self->{encoding_text}->signal_connect("activate",sub {$self->encoding_list_changed});
        $self->{encoding_list}->signal_connect("changed",sub {$self->encoding_list_changed});
        $self->{hot_list_entry} = $self->{hot_list}->get_child();
        $self->{hot_list_entry}->signal_connect("activate",sub {$self->hot_list_changed});
#        $self->{hot_list}->signal_connect("changed",sub {$self->hot_list_changed});

#        foreach(keys %WIDGETS_MAP) {
#            NightGun::App::dump("Gui",[$self->{$_}],[$_]);
#        }

        $self->{encoding_list}->append_text($_) foreach(qw/auto utf8 gb2312 big5/);
        $self->init_tree;
        NightGun::App::fill_about_dialog($self->{about_window});
        my $contentView = NightGun::Gui::ContentView->new();
#        use NightGun::Gui::TextView;
#        my $contentView = NightGun::Gui::TextView->new();
        $self->{content_paned}->add($contentView->{widget});
        $contentView->show();
#        $contentView->
        #NightGun::App::VIEW);
        #$contentView->attatch($self->{content_notebook},$self->{content_textview});
        $self->{content}=$contentView;
        $self->{content}->{listener}->{status_changed}=sub {$self->statusbar_set(_to_gtk_a(@_));};
        $self->{content}->{listener}->{location}=sub {$self->location_changed(@_);};
		$self->{content}->{listener}->{title}=sub {
			$self->main_set_title(_to_gtk_a(@_));
		};
		$self->{content}->{listener}->{progress}=sub {
			$self->progress(@_);
		};
#                $self->{content}->{listener}->{notebook_key_released} = sub {
#                        $self->content_key_up(@_);
#                };
#        $self->{content_notebook}->signal_connect("key-release-event",sub { $self->content_key_up(@_);});
        $self->{main_window}->maximize;
        return $self->{glade};
    }
}

sub zoom_in {
    my $self=shift;
    my($r,$font)=$self->{content}->zoom_in();
    $self->{options}{font}=$font->to_string() if($font);
    return $r;
}
sub zoom_out {
    my $self=shift;
    my($r,$font)=$self->{content}->zoom_out();
    $self->{options}{font}=$font->to_string() if($font);
    return $r;
}

sub _select_path {
    my($self,$tree,$model,$sel,$iter,$path) = @_;
    $sel->select_iter($iter);
    $tree->scroll_to_cell($path,,undef,0,0,0);
    my $filename = $model->get_value($iter,1);
    $self->{events}->{file_list_selected}($filename) if($filename);
    return 1;
}

sub go_back {
    my $self=shift;
    unless($self->{content}->go_back()) {
    }
}
sub go_forward {
    my $self=shift;
    unless($self->{content}->go_forward()) {
    }
}
sub go_next {
    my $self = shift;
    my $list = $self->{left};
    my $model = $list->get_model;
    my $sel = $list->get_selection;
    my (undef,$iter) = $sel->get_selected;
    my $path;
    if($iter) {
        $path = $model->get_path($iter);
        my $saved_path = $path->to_string;
        $path->next;
        if(!($path->to_string eq $saved_path)) {
            $iter = $model->get_iter($path);
            if($iter) {
                return $self->_select_path($list,$model,$sel,$iter,$path);
            }
        }
    }
    my $first = Gtk2::TreeModel::get_iter_first($model);
    return unless($first);
    $first = Gtk2::TreeModel::iter_next($model,$first); #Ingored first item, the parent node
    return unless($first);
    $iter = $first;
    $path = $model->get_path($iter);
    return $self->_select_path($list,$model,$sel,$iter,$path);
}
sub go_previous {
    my $self = shift;
    my $list = $self->{left};
    my $model = $list->get_model;
    my $sel = $list->get_selection;
    my (undef,$iter) = $sel->get_selected;
    my $first = Gtk2::TreeModel::get_iter_first($model);
    return unless($first);
    my $path;
    if($iter) {
        $path = $model->get_path($iter);
        my $first_path = $model->get_path($first)->to_string;
        if($path->prev and !($path->to_string eq $first_path) ) {
            $iter = $model->get_iter($path);
            if($iter) {
                return $self->_select_path($list,$model,$sel,$iter,$path);
            }
        }
    }
    $iter = $first;
    while(my $next = Gtk2::TreeModel::iter_next($model,$iter)) {
        $iter = $next;
    }
    $path = $model->get_path($iter);
    return $self->_select_path($list,$model,$sel,$iter,$path);
}

sub init_tree {
    my $self=shift;
    my $tree = $self->{left};
    my $tr_left_model = Gtk2::TreeStore->new("Glib::String","Glib::String","Glib::String");
    $tree->set_model($tr_left_model);
    my $renderer = Gtk2::CellRendererText->new();
    #$renderer->set("foreground","blue");
    my $column = Gtk2::TreeViewColumn->new_with_attributes("List",$renderer,"text",0,"foreground",2);
    $tree->append_column($column);
    #$column = Gtk2::TreeViewColumn->new_with_attributes("Path",$renderer,"text",1);
    #$tr_left->append_column($column);
}
sub file_list_add {
    my $self=shift;
    my $tree_model = $self->{left}->get_model;
    while(@_) {
        my $text=shift @_;
        my $data=shift @_;
        my $iter = $tree_model->append(undef);
        $tree_model->set_value($iter,0,$text,1,$data);#,2,"blue");
    }
}
sub file_list_set {
    my $self=shift;
    $self->{left}->get_model->clear;
    $self->file_list_add(@_);
}

sub file_list_select_item {
    my $self=shift;
    my $data=shift;
    my $tree = $self->{left};
    my $tree_model = $tree->get_model;
    my $iter = Gtk2::TreeModel::get_iter_first($tree_model);
    while($iter) {
        my $item = Gtk2::TreeModel::get_value($tree_model,$iter,1);
        if($item and $item eq $data) {
#            print STDERR "TREE PATH: " . $tree_model->get_path($iter)->to_string;
            my $sel = $tree->get_selection;
            $sel->select_iter($iter);
            $tree->scroll_to_cell($tree_model->get_path($iter),undef,0,0,0);
            return 1;
        }
        $iter = Gtk2::TreeModel::iter_next($tree_model,$iter);
    }
    return undef;
}


sub content_set_uri {
	my $self=shift;
	return $self->{content}->set_uri(@_);
}
sub content_set_stream {
	my $self=shift;
	return $self->{content}->set_stream(@_);
}

sub content_set {
    my $self=shift;
    return $self->{content}->set_content(@_);
}
sub content_get {
    my $self=shift;
    return $self->{content}->get_content;
}
sub run {
    my $self=shift;
    $self->update;
    $self->{main_window}->show;
    Gtk2->main;
}

sub select_dir {
    my $self=shift;
    my $current = $self->{hot_list}->get_active_text;
    my $file = MyPlace::Gtk2::select_dir("",$self->{main_window},$current);
    return unless($file);
    $self->hot_list_add_uniq($file);
    return unless($self->{events}{main_select_dir});
    $self->{events}->{main_select_dir}($file);
}
sub location_changed {
    my $self=shift;
    return unless($self->{events}{location_changed});
    $self->{events}->{location_changed}(@_);
}
sub select_file {
    my $self=shift;
    my $current = $self->{hot_list}->get_active_text;
    my $file = MyPlace::Gtk2::select_file("",$self->{main_window},"open",$current);
    return unless($file);
    $self->hot_list_add_uniq($file);
    return unless($self->{events}{main_select_file});
    $self->{events}->{main_select_file}($file);
}
sub hot_list_add {
    my $self=shift;
    foreach(@_) {
        $self->{hot_list}->append_text($_);
    }
}
sub hot_list_add_uniq {
    my ($self,$text) = @_;
    return unless($text);
    MyPlace::Gtk2::combox_add_unique_text($self->{hot_list},$text);
}
sub quit {
    my $self = shift;
    if($self->{events}{main_destory}) {
        $self->{events}->{main_destory}();
    }
    Gtk2->main_quit;
}

sub file_list_selected {
    my $self=shift;
    return unless($self->{events}{file_list_selected});
    my $list = $self->{left};
    my $sel = $list->get_selection;
    my ($model,$iter) = $sel->get_selected;
    return unless($iter);
    my $filename = $model->get_value($iter,1);
    return unless($filename);
    $self->{events}->{file_list_selected}($filename);
}
sub hot_list_clear_clicked {
	my $self=shift;
	#$self->{hot_list}->clear();
	$self->{hot_list}->get_model->clear();
}
sub hot_list_add_clicked {
	goto &hot_list_changed;
}
sub hot_list_changed { 
    my $self=shift;
    return unless($self->{events}{hot_list_changed});
    my $file=$self->{hot_list}->get_active_text;
    $self->hot_list_add_uniq($file);
    return unless($file);
    $self->{events}->{hot_list_changed}($file);
}

sub encoding_text_changed {
    my $self=shift;
    if(!$self->{encoding_text}->is_focus()) {
        $self->encoding_list_changed();
    }
    return undef;
}
sub encoding_list_changed {
    my $self=shift;
    return unless($self->{events}{encoding_changed});
    my $enc = $self->{encoding_text}->get_text;
    unless($enc eq $self->{options}{encoding}) {
        $self->{options}{encoding}=$enc;
        $self->{events}->{encoding_changed}($enc);
    }
    return undef;
}

sub hot_list_get_texts {
    my $self=shift;
    my $combox=$self->{hot_list};
    return unless($combox);
    my @result;
    my $model = $combox->get_model;
    my $iter = Gtk2::TreeModel::get_iter_first($model);
    while($iter) {
        push @result,Gtk2::TreeModel::get_value($model,$iter);
        $iter = Gtk2::TreeModel::iter_next($model,$iter);
    }
    return reverse @result;
}
sub hot_list_set_text {
    my $self=shift;
    $self->{hot_list_entry}->set_text(@_);
}

sub hot_list_set_texts {
    my $self=shift;
    my $combox=$self->{hot_list};
    return unless($combox);
    $combox->clear;
    $self->hot_list_add(@_);
}

sub main_set_title {
    my $self=shift;
    $self->{main_window}->set_title(@_);
}
sub main_get_title {
    my $self=shift;
    $self->{main_window}->get_title(@_);
}
sub statusbar_set {
    my $self=shift;
    $self->{status_bar}->pop(0);
    $self->{status_bar}->push(0,@_);
}
sub load_config {
    my ($self,$config)=@_;
    return unless($config);
    my @config = @{$config->{state}} if(ref $config->{state});
    $self->update;
    $self->{main_window}->move(shift @config,shift @config);
    $self->{main_window}->set_default_size(shift @config,shift @config);
    $self->{content_paned}->set_position(shift @config || 150);
    $self->{options}{wordwrap}=shift @config;
    $self->{options}{font}=shift @config;
    $self->{options}{forecolor}=shift @config;
    $self->{options}{backcolor}=shift @config;
    $self->{options}{leftmargin}=shift @config;
    $self->{options}{rightmargin}=shift @config;
    $self->{options}{lineindent}=shift @config;
    $self->{options}{linepadding}=shift @config;
    $self->{options}{showpanel}=shift @config;
    $self->{options}{showlist}=shift @config;
    $self->{options}{encoding}=shift @config;
    $self->set_widget;
    $self->update; 
}
sub save_config {
    my ($self,$config) = @_;
    my @config;
    $self->update;
    push @config, $self->{main_window}->get_position;
    push @config, $self->{main_window}->get_size;
    push @config, $self->{content_paned}->get_position;
    push @config,  $self->{options}{wordwrap} ? 1 : 0;
    push @config, $self->{options}{font};
    push @config, $self->{options}{forecolor} || "#FFFFFF";
    push @config, $self->{options}{backcolor} || "#000000";
    push @config, $self->{options}{leftmargin} || 0;
    push @config, $self->{options}{rightmargin} || 0;
    push @config, $self->{options}{lineindent} || 0;
    push @config, $self->{options}{linepadding} || 0;
    push @config, $self->{options}{showpanel} ? 1 : 0;
    push @config, $self->{options}{showlist} ? 1 : 0;
    push @config, $self->{options}{encoding} || "auto";
    $config->{state}=\@config;
}

sub content_scrolled {
    my $self=shift;
    print STDERR "content_scrolled\n";
}
sub update {
        while(Gtk2->events_pending) {
            Gtk2->main_iteration_do(1);
        } 
}
sub content_get_position {
    my $self=shift;
    #$self->update;
    return $self->{content}->get_state; #visible_rect->values;
}
sub content_set_position {
    my $self=shift;
    #$self->update;
    return $self->{content}->set_state(@_);
    #$self->update;
}

sub progress {
	my($self,$min,$max) = @_;
#	print STDERR "$min/$max\n";
	if($min == $max) {
		$self->{progress_bar}->set_fraction(0);
	}
	else {
		$self->{progress_bar}->pulse();
	}
	return 1;
}

sub content_begin_set {
    my $self=shift;
  #  $self->{hot_list}->set_sensitive(0);
  #  $self->{left}->set_sensitive (0);
  #  $self->{content}->set_sensitive(0);
    $self->{progress_bar}->set_text("loading");
    $self->{progress_bar}->set_pulse_step(0.1);
    #$self->{progress_window}->show_all;
    #$self->{hp_content}->remove($self->{sw_content});
    #$self->{hp_content}->add($self->{fake_content});
    #$self->{sw_content}->hide;
}
sub content_progress_set {
    my $self=shift;
    $self->{progress_bar}->pulse();
}
sub content_end_set {
    my $self=shift;
    $self->{progress_bar}->set_text("");
    $self->{progress_bar}->set_fraction(0);
  #  $self->{hot_list}->set_sensitive(1);
  #  $self->{left}->set_sensitive (1);
  #  $self->{content}->set_sensitive(1);
    #$self->{progress_window}->hide;
    #$self->{hp_content}->remove($self->{fake_content});
    #$self->{hp_content}->add($self->{sw_content});
    #$self->{sw_content}->show;
}
sub preference_show {
    my $self=shift;
    $self->{options_word_wrap}->set_active($self->{options}{wordwrap});
    $self->{options_font}->set_font_name($self->{options}{font}) if($self->{options}{font});
    $self->{options_fore_color}->set_color(
        Gtk2::Gdk::Color->parse($self->{options}{forecolor}
        )) if($self->{options}{forecolor});
    $self->{options_back_color}->set_color(
        Gtk2::Gdk::Color->parse($self->{options}{backcolor}
        )) if($self->{options}{backcolor});
    $self->{options_left_margin}->set_value($self->{options}{leftmargin});
    $self->{options_right_margin}->set_value($self->{options}{rightmargin});
    $self->{options_line_indent}->set_value($self->{options}{lineindent});
    $self->{options_line_padding}->set_value($self->{options}{linepadding});
    $self->{options_window}->show_all;
}
sub options_apply {
    my $self=shift;
    $self->set_options;
}
sub options_cancel {
    my $self=shift;
    $self->{options_window}->hide;
}
sub options_ok {
    my $self=shift;
    $self->set_options;
    $self->{options_window}->hide;
}
sub set_options {
    my $self=shift;
    $self->{options}{wordwrap}=$self->{options_word_wrap}->get_active;
    $self->{options}{font}=$self->{options_font}->get_font_name;
    $self->{options}{forecolor}=$self->{options_fore_color}->get_color->to_string;
    $self->{options}{backcolor}=$self->{options_back_color}->get_color->to_string;
    $self->{options}{leftmargin}=$self->{options_left_margin}->get_value;
    $self->{options}{rightmargin}=$self->{options_right_margin}->get_value;
    $self->{options}{lineindent}=$self->{options_line_indent}->get_value;
    $self->{options}{linepadding}=$self->{options_line_padding}->get_value;
#    $self->{options}{encoding1}=$self->{options_encoding_entry1}->get_text;
#    $self->{options}{encoding2}=$self->{options_encoding_entry2}->get_text;
    $self->set_widget; 
}

sub get_options_control {
    my ($self,$name)=shift;
    $name =~ s/^[^_]+_//;
    return $self->{glade}->get_widget($name) if($name);
    return undef;
}

sub get_options {
    my ($self,$name)=shift;
    my $type = $name;
    $type =~ s/_.*$//g;
    $name =~ s/^[^_]+_//;
    my $widget = $self->{glade}->get_widget("options" . $name);
    if($widget) {
        my $result;
        if($type eq "color") {
            $result = $widget->get_color->to_string;
        }
        elsif ($type eq "font") {
            $result = $widget->get_font_name;
        }
        elsif ($type eq "check") {
            $result = $widget->get_active;
        }
        else {
            $result = $widget->get_value;
        }
        return $result;
    }
    else {
        print STDERR "No Widget named $name!\n";
        return undef;
    }
}

sub set_widget {
    my $self=shift;
    #use Data::Dumper;
    #print STDERR Dumper($self->{options}),"\n";
    my $content = $self->{content};
    my %options = %{$self->{options}};
    if($options{wordwrap}) {
        $content->set_wrap_mode("word");
    }
    else {
        $content->set_wrap_mode("none");
    }
    $self->{left}->modify_text("normal",Gtk2::Gdk::Color->parse($options{forecolor})) if($options{forecolor});
    $self->{left}->modify_base("normal",Gtk2::Gdk::Color->parse($options{backcolor})) if($options{backcolor});
    $self->{hot_list_entry}->modify_base("normal",Gtk2::Gdk::Color->parse($options{forecolor})) if($options{forecolor});
    $self->{hot_list_entry}->modify_text("normal",Gtk2::Gdk::Color->parse($options{backcolor})) if($options{backcolor});
    $content->modify_font(Gtk2::Pango::FontDescription->from_string($options{font})) if($options{font});
    $content->modify_text("normal",Gtk2::Gdk::Color->parse($options{forecolor})) if($options{forecolor});
    $content->modify_base("normal",Gtk2::Gdk::Color->parse($options{backcolor})) if($options{backcolor});
    $content->set_left_margin($options{leftmargin});
    $content->set_right_margin($options{rightmargin});
    $content->set_indent($options{lineindent});
    $content->set_pixels_below_lines($options{linepadding}/2);
    $content->set_pixels_above_lines($options{linepadding}/2);
    $content->set_pixels_inside_wrap($options{linepadding});
    $self->{show_list}->set_active($options{showlist});
    $self->{show_panel}->set_active($options{showpanel});
    $self->{encoding_text}->set_text($options{encoding} || 'auto');
}

sub hot_list_show {
    my $self=shift;
    $self->{options}{showlist}=$self->{show_list}->get_active;
    if($self->{options}{showlist}) {
        $self->{hotlist_box}->show;
    }
    else {
        $self->{hotlist_box}->hide;
    }
}
sub file_list_show {
    my $self=shift;
    $self->{options}{showpanel}=$self->{show_panel}->get_active;
    if($self->{options}{showpanel}) {
        $self->{left_window}->show;
    }
    else {
        $self->{left_window}->hide;
    }
}
sub about {
    my $self=shift;
    $self->{about_window}->show_all;
    $self->{about_window}->run;
    $self->{about_window}->hide;
}

sub debug {
    my $self=shift;
    print STDERR "Begin debug in $self\n";
        while(<STDIN>) {
            chomp;
            print STDERR ":";
            eval "print STDERR $_;print STDERR '\n';";
            $self->update;
        }
        print STDERR "End debug in $self\n";
}

sub AUTOLOAD {
        my $self = shift;
        my $name = our $AUTOLOAD;
        return if ($name =~ /::DESTROY$/);
        $name =~ s/^.*:://g;
        print STDERR "AUTOLOAD $name\n";
        return $self->{main_window}->$name(@_);
}
1;
