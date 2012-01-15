#!/usr/bin/perl -w
# $Id$
use strict;
require v5.8.0;
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
my $USERID = shift;
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
#my $blogs_url;
#if($result =~ m/cacheFileUrl:"([^"]+)"/) {
#    $blogs_url = 'http://' . $1;
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
#my (undef,$blogs_data) = $HTTP->get($blogs_url,'charset:gbk');
#my $blogs = convert_from_html($blogs_data);
use MyPlace::163::Blog;
my $blog = MyPlace::163::Blog->new($USERNAME,$USERID);
my $blogs = $blog->get_blogs();

if(!$blogs) {
#    print STDERR $blogs_data,"\n";
    print STDERR ("Couldn't get blogs data!\n");
    exit 1;
}
else {
	print join("\n",@{$blogs}),"\n";
}

__END__

=pod

=head1  NAME

blog.163.com - PERL script

=head1  SYNOPSIS

blog.163.com username [album_id|album_name]...

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
