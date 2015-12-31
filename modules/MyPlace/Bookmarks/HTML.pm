#!/usr/bin/perl -w
package MyPlace::Bookmarks::HTML;
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

sub header {
	return <<'HEAD';
<!DOCTYPE NETSCAPE-Bookmark-file-1>
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
<!-- This is an automatically generated file.
It will be read and overwritten.
Do Not Edit! -->
<TITLE>Bookmarks</TITLE>
<H1>Bookmarks</H1>
<DL><p>
HEAD
}

sub footer {
	return <<'FOOT';
</DL><p>
FOOT
}

sub bookmark {
	my $uri = shift;
	my $date;
	my $title;
	my $desc;
	my $tags;
	my $private;
	if(!ref $uri) {
		unshift @_,$uri;
		my %uri = @_;
		$uri = \%uri;
	};
	$date = $uri->{dateAdded} || $uri->{date} || $uri->{added} || $uri->{modified} || '';
	$date = substr($date,0,10) if($date);
	$title = $uri->{title} || $uri->{text} || '';
	$desc = $uri->{desc} || $uri->{description} || '';
	if($uri->{tags}) {
		$tags = ref $uri->{tags} ? join(",",@{$uri->{tags}}) : $uri->{tags};
	}
	$tags = '' unless($tags);
	$private = $uri->{private} || '0';
	$uri = $uri->{uri} || $uri->{url};
	return	'<DT><A HREF="' . $uri .
			'" ADD_DATE="' . $date .
			'" PRIVATE="' . $private . 
			'" TAGS="' . $tags . 
			'">' . $title . '</A>' . "\n" . 
			'<DD>' . $desc  . "\n";
}

1;

__END__
=pod

=head1  NAME

MyPlace::Bookmarks::HTML - PERL Module

=head1  SYNOPSIS

use MyPlace::Bookmarks::HTML;

=head1  DESCRIPTION

___DESC___

=head1  CHANGELOG

    2012-06-17 22:54  xiaoranzzz  <xiaoranzzz@myplace.hell>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@myplace.hell>


# vim:filetype=perl

