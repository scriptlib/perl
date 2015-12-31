#!/usr/bin/perl -w
#subclass Gtk2::ComboBox
package MyPlace::Gtk2::SCComboBox;
use strict;
use warnings;
use Gtk2;

sub new {
    my ($class,$object) = @_;
    return bless {OBJ=>$object},$class;
}

sub clear {
    my $self=shift;
    my $combox=$self->{OBJ};
    return unless($combox);
    $combox->clear();
}

sub get_all {
    my $self=shift;
    my $combox=$self->{OBJ};
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

sub add {
    my $self=shift;
    my $combox=$self->{OBJ};
    return unless($combox);
    foreach(@_) {
        $combox->append_text($_);
    }
}

sub uadd {
    my $self=shift;
    my $combox=$self->{OBJ};
    return unless($combox);
    my $text=shift;
    my $append=shift;
    return unless($text);
    my $model = $combox->get_model;
    my $iter = Gtk2::TreeModel::get_iter_first($model);
    my $match=0;
    my $count=0;
    if($iter) {
        while($iter) {
            $count++;
            my $value=Gtk2::TreeModel::get_value($model,$iter); 
            if($value eq $text) {
                $match=1;
                $combox->set_active_iter($iter);
                last;
            }
            $iter=Gtk2::TreeModel::iter_next($model,$iter);
        }
	}
    	unless($match) {
#			print STDERR "Adding $text\n";
        	if($append) {
	            $combox->append_text($text);
    	        $combox->set_active($count);
        	}
	        else {
    	       $combox->prepend_text($text);
        	   $combox->set_active(0);
	        }
    	}
        
}

1;
