#!/usr/bin/perl -w
package NightGun::App;
BEGIN {
use constant {
    NAME => 'NightGun',
    VERSION => '1.0',
    AUTHORS => 'xiaoranzzz@myplace.hell',
    COPYRIGHT => 'xiaoranzzz@myplace.hell 2008',
    COMMENTS => 'text reader suitable for night reading',
    DATE => '2008-12-31',
    GUI => 'GTK2',
    VIEW => 'MozEmbed',
#    VIEW => 'Normal',
    DEBUG => 1
};
    if(not NightGun::App::DEBUG) {
        eval 'sub dump {};';
    }
    else {
        eval '
            use Data::Dumper;
            sub dump  {foreach(@_){print STDERR (Dumper($_),"\n");}};
        ';
    }
}
sub fill_about_dialog {
    my $about_window = shift;
    $about_window->set_authors(AUTHORS);
    $about_window->set_copyright(COPYRIGHT);
    $about_window->set_program_name(NAME);
    $about_window->set_version(VERSION);
    $about_window->set_comments(COMMENTS);
    return $about_window;
}
1;

