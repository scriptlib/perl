#!/usr/bin/perl -w
package NightGun::App;
use Exporter;
use Term::ANSIColor;
use Data::Dumper;
my $VERSION = 1.15;
use constant {
    NAME => 'NightGun',
    VERSION => '1.15',
    AUTHORS => 'xiaoranzzz@myplace.hell',
    COPYRIGHT => 'xiaoranzzz@myplace.hell 2008',
    COMMENTS => 'text reader suitable for night reading',
    DATE => '2010-05-18',
    GUI => 'GTK2',
#    VIEW => 'MozEmbed',
    LOGING => 0,
#    VIEW => 'Normal',
    DEBUG => 1,
};
use constant {
    WARN_COLOR=>color('yellow'),
    MSG_COLOR=>color('green'),
    ERR_COLOR=>color('red'),
    NO_COLOR=>color('reset'),
    HD_COLOR=>color('bold'),
};

our @ISA=qw/Exporter/;
our @EXPORT=qw/&message &warn &error &say &dump/;
sub _build_hd {
    my $hd =shift;
    $hd = $hd ? "NightGun::$hd>" : "NightGun>";
}
sub message {
    no warnings;
    my $hd=shift;$hd = _build_hd($hd);
    print STDERR HD_COLOR,$hd,NO_COLOR,MSG_COLOR,@_,NO_COLOR,"\n";
}
sub warn {
    no warnings;
    my $hd=shift;$hd = _build_hd($hd);
    print STDERR HD_COLOR,$hd,NO_COLOR,WARN_COLOR,@_,NO_COLOR,"\n";
}
sub error {
    no warnings;
    my $hd=shift;$hd = _build_hd($hd);
    print STDERR HD_COLOR,$hd,ERR_COLOR,@_,NO_COLOR,"\n";
}
sub say {
    my $hd=shift;$hd = _build_hd($hd);
    print STDERR HD_COLOR,$hd,NO_COLOR,@_,NO_COLOR,"\n";
}
sub dump {
    my $hd=shift;$hd = _build_hd($hd);
    print STDERR HD_COLOR,$hd,NO_COLOR,Data::Dumper->Dump(@_),NO_COLOR,"\n";  
}
sub debug {
    return unless(NightGun::App::DEBUG);
    my $hd=shift;$hd = _build_hd($hd);
    print STDERR HD_COLOR,$hd,ERR_COLOR,@_,NO_COLOR,"\n";
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

