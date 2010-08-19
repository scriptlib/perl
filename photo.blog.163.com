#!/usr/bin/perl -w
# $Id$
use strict;
require v5.10.0;
our $VERSION = 'v0.1';

BEGIN
{
    my $PROGRAM_DIR = $0;
    $PROGRAM_DIR =~ s/[^\/\\]+$//;
    $PROGRAM_DIR = "./" unless($PROGRAM_DIR);
    unshift @INC, 
        map "$PROGRAM_DIR$_",qw{modules lib ../modules ..lib};
}

my %OPTS;
my @OPTIONS = qw/help|h|? version|ver edit-me manual|man/;

if(@ARGV)
{
    require Getopt::Long;
    require MyPlace::Usage;
    Getopt::Long::GetOptions(\%OPTS,@OPTIONS);
    MyPlace::Usage::Process(\%OPTS,$VERSION);
}
else
{
    require MyPlace::Usage;
    MyPlace::Usage::PrintHelp();
}

use Encode;
my $_UTF8 = find_encoding('utf8');
binmode STDOUT,'utf8';
binmode STDERR,'utf8';
my $USERNAME = shift;
my @QUERYS = map {$_UTF8->decode($_)} @ARGV;

#use MyPlace::HTTPGet;
#my $api_url = 'http://photo.163.com/photo/' . $USERNAME . '/dwr/call/plaincall/UserSpaceBean.getUserSpace.dwr?';
#my $sess_id = 100+int(rand(1)*100+1);
#my $batch_id = 577000 + int(rand(1)*1000+1);
#my $request = $api_url . "callCount=1&scriptSessionId=\${scriptSessionId}$sess_id&c0-scriptName=UserSpaceBean&c0-methodName=getUserSpace&c0-id=0&c0-param0=string:$USERNAME&batchId=$batch_id";
#
#my $HTTP = MyPlace::HTTPGet->new();
#my (undef,$result) = $HTTP->get($request);
#
#my $albums_url;
#if($result =~ m/cacheFileUrl:"([^"]+)"/) {
#    $albums_url = 'http://' . $1;
#}
#else {
#    print STDERR $result,"\n";
#    exit 1;
#}
#
#use Data::Dumper;
#sub convert_from_html {
#    my $html_data = shift;
#    if($html_data =~ m/var\s+g_[pa]\$\d+d\s*=\s*(\[\{.+\}\])\s*;/s) {
#        $html_data = $1;
#        $html_data =~ s/:/=>/g;
#        $html_data =~ s/true/"true"/g;
#        my $r = eval($html_data);
#        if($@) {
#            print STDERR $@,"\n";
#            return undef;
#        }
#        elsif((!$r) or (!@{$r})) {
#            return undef;
#        }
#        return $r;
#    }
#    else {
#        return undef;
#    }
#}
#
#my (undef,$albums_data) = $HTTP->get($albums_url,'charset:gbk');
#my $albums = convert_from_html($albums_data);
use MyPlace::163::Blog;
my $blog = MyPlace::163::Blog->new($USERNAME);
my $albums = $blog->get_albums();

if(!$albums) {
#    print STDERR $albums_data,"\n";
    print STDERR ("Couldn't get albums data!\n");
    exit 1;
}

print STDERR "Get ",scalar(@{$albums})," album(s).\n";
if(@QUERYS) {
    my @new_albums;
    foreach my $id_or_name (@QUERYS) {
        foreach(@{$albums}) {
            if($id_or_name eq $_->{name}) {
                push @new_albums,$_;
            }
            elsif($id_or_name eq $_->{id}) {
                push @new_albums,$_;
            }
        }
    }
    $albums = \@new_albums;
    print STDERR "Download ",scalar(@new_albums), " album(s) from all.\n";
}
#my $pic_host = 'http://img.ph.126.net/';
#my $pic_host_1 = 'http://img';
#my $pic_host_2 = '.ph.126.net/';
#my $blog_host = 'http://img.bimg.126.net/photo/';
#my $blog_host_1 = 'http://img';
#my $blog_host_2 = '.bimg.126.net/photo/';
#
#sub convert_pic_url {
#    my $picture = shift;
#    if($picture->{ourl} =~ m/^(\d*)\/photo\/(.+)$/o) {
#            return $1 ? $blog_host_1 . $1 . $blog_host_2 . $2 : $blog_host . $2;
#    }
#    elsif($picture->{ourl} =~ m/^(\d*)\/(.+)$/o) {
#            return $1 ? $pic_host_1 . $1 . $pic_host_2 . $2 : $pic_host . $2;
#    }
#}

foreach my $album (@{$albums}) {
    print STDERR $album->{name},":",$album->{desc},"\n",'http://' . $album->{purl},"\n";
#    my (undef,$pictures_data) = $HTTP->get('http://' . $album->{purl},'charset:gbk');
#    my $pictures = convert_from_html($pictures_data);
#    print STDERR Dumper($pictures),"\n";
    my $pictures = $blog->get_pictures($album);
    if($pictures) {
        print "#BATCHGET:chdir:",$album->{name},"\n";
        foreach my $picture (@{$pictures}) {
            print $picture->{url},"\n";
#            print convert_pic_url($picture),"\n";
        }
    }
    else {
        print STDERR "Couldn't get pictures of [",$album->{name},"]\n";
    }
    sleep 2;
#    print STDERR $pictures_data,"\n";
}

__END__

=pod

=head1  NAME

photo.blog.163.com - PERL script

=head1  SYNOPSIS

photo.blog.163.com username [album_id|album_name]...

=head1  OPTIONS

=over 12

=item B<--version>

Print version infomation.

=item B<-h>,B<--help>

Print a brief help message and exits.

=item B<--manual>,B<--man>

View application manual

=item B<--edit-me>

Invoke 'editor' against the source

=back

=head1  DESCRIPTION

___DESC___

=head1  CHANGELOG

    2010-08-18  xiaoranzzz  <xiaoranzzz@myplace.hell>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@myplace.hell>

=cut

#       vim:filetype=perl
