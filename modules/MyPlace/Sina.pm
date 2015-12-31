#!/usr/bin/perl -w
package MyPlace::Sina;
use strict;
use warnings;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw();
    @EXPORT_OK      = qw();
}

our $login_url1 = 'http://login.sina.com.cn/sso/login.php?client=ssologin.js(v1.3.9) ';
our $login_url2 = 'http://t.sina.com.cn/ajaxlogin.php?framelogin=1&callback=parent.sinaSSOController.feedBackUrlCallBack&retcode=0';

use MyPlace::Curl;
my $curl = MyPlace::Curl->new();
my $cookie = $ENV{HOME} . "/.curl_cookies.dat";
$curl->set('cookie',$cookie);
$curl->set('cookie-jar',$cookie);

sub new {my $class = shift;return bless {@_},$class;}

sub check {
    goto &login;
}

sub login {
    my($self,$user,$passwd,$referer) = @_;
    $user = $self->{user} unless $user;
    $passwd = $self->{passwd} unless $passwd;
    $referer = $self->{referer} unless $referer;
    $user =~ s/\@/%40/g;
    $curl->get($login_url1,"--referer",$referer,"--data","service=miniblog&client=ssologin.js%28v1.3.9%29&entry=miniblog&encoding=utf-8&gateway=1&savestate=7&from=&useticket=0&username=$user&password=$passwd&url=http%3A%2F%2Ft.sina.com.cn%2Fajaxlogin.php%3Fframelogin%3D1%26callback%3Dparent.sinaSSOController.feedBackUrlCallBack&returntype=META");
    return $curl->get($login_url2,"--referer",$login_url1);
}

sub get {
    my $self = shift;
    return $curl->get(@_);
}

1;

__END__
=pod

=head1  NAME

MyPlace::Sina - PERL Module

=head1  SYNOPSIS

use MyPlace::Sina;

=head1  DESCRIPTION

___DESC___

=head1  CHANGELOG

    2010-11-09 22:01  xiaoranzzz  <xiaoranzzz@myplace.hell>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@myplace.hell>


# vim:filetype=perl
