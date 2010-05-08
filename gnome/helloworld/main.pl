#!/usr/bin/perl -w

use strict;
use Gnome2;

my $APPNAME="Hello World";
my $APPVER="0.1";

Gnome2::Program->init($APPNAME,$APPVER);

my $APPWIN = Gnome2::App->new($APPNAME,$APPNAME);
$APPWIN->set_default_size(400,300);
signal_connect $APPWIN 'delete_event', sub { Gtk2->main_quit; return 0 };

my $label = Gtk2::Label->new("Hello,World!");

$APPWIN->set_contents($label);

$APPWIN->show;

Gtk2->main;



