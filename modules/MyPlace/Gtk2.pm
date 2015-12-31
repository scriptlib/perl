#!/usr/bin/perl -w
package MyPlace::Gtk2;
use strict;
use warnings;
use Gtk2;

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
    #&select_file &select_dir &combox_add_unique_text &combox_get_texts);
    @EXPORT_OK      = qw();
}
sub select_file {
    my $title=shift;
    my $parent=shift;
    my $action=shift;
    my $default=shift;
    $title="Select File..." unless($title);
    $parent=0 unless($parent);
    $action="open" unless($parent);
    my $dlg = Gtk2::FileChooserDialog->new($title,$parent,$action,'gtk-cancel'=>'cancel','gtk-ok'=>'ok');
    if($dlg) {
        $dlg->set_filename($default) if($default);
        $dlg->show_all;
        my $re = $dlg->run;
        my $file;
        if($re eq "ok") {
            $file=$dlg->get_filename;
        }
        $dlg->destroy;
        return $file;
    }
    return undef;
}
sub select_dir {
    my $title=shift;
    my $parent=shift;
    my $default=shift;
    return select_file($title,$parent,"select_folder",$default);
}
sub combox_get_texts {
    my $combox=shift;
    return unless($combox);
    my @result;
    my $model = $combox->get_model;
    my $iter = Gtk2::TreeModel::get_iter_first($model);
    while($iter) {
        push @result,Gtk2::TreeModel::get_value($model,$iter);
        $iter = Gtk2::TreeModel::iter_next($model,$iter);
    }
    return @result;
}
sub combox_add_texts {
    my $cbo = shift;
    my @items = @_;
    if($cbo and @items) {
        $cbo->append_text($_) foreach(@items);
        return 1;
    }
    return undef;
}

sub combox_add_unique_text {
    my $combox=shift;
    my $text=shift;
    my $append=shift;
    return unless($combox);
    return unless($text);
    my $model = $combox->get_model;
    my $iter = $model->get_iter_first;#($model);
    my $match=0;
    my $count=0;
    if($iter) {
        while($iter) {
            $count++;
            my $value=$model->get_value($iter); 
            if($value eq $text) {
                $match=1;
                #$combox->set_active_iter($iter);
                last;
            }
            $iter=Gtk2::TreeModel::iter_next($model,$iter);
        }
	}
    	unless($match) {
        	if($append) {
                    my $iter = Gtk2::ListStore::append($model);#->prepend(undef);
                    Gtk2::ListStore::set_value($model,$iter,0,$text);
                    $combox->set_active_iter($iter);
        	}
	        else {
                    my $iter = Gtk2::ListStore::prepend($model);#->prepend(undef);
                    Gtk2::ListStore::set_value($model,$iter,0,$text);
                    $combox->set_active_iter($iter);
	        }
    	}
        
}

1;
