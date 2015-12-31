#!/usr/bin/perl -w
use strict;
use warnings;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw(
		&rss_start
		&rss_item
		&rss_end
		$RSS_TEMPLATE
	);
    @EXPORT_OK      = qw();
}
1;

our %RSS_TEMPLATE = ();
our $RSS_TEMPLATE = \%RSS_TEMPLATE;

$RSS_TEMPLATE{START} = <<BLOCK
	<?xml version="1.0" encoding="UTF-8"?>
	<rss xmlns:dc="http://purl.org/dc/elements/1.1/" version="2.0">
	<channel>
	<description>####DESCRIPTION####</description>
	<title>####TITLE####</title>
	<generator>####GENERATOR####</generator>
BLOCK
;
$RSS_TEMPLATE{DEFAULT_START} = {
	'description'=>'',
	'title'=>'',
	'generator'=>'MyPlace RSS generator',
};
$RSS_TEMPLATE{END} = <<BLOCK
	</channel>
	</rss>
BLOCK
;
$RSS_TEMPLATE{DEFAULT_END} = undef;

$RSS_TEMPLATE{ITEM} = <<BLOCK
	<item>
	<title>####TITLE####</title>
	<author>####AUTHOR####</author>
	<description>
<![CDATA[
	####DESCRIPTION####
]]>
	</description>
	<link>####LINK####</link>
	<guid>####GUID####</guid>
	<pubDate>####PUBDATE####</pubDate>
	</item>
BLOCK
;
$RSS_TEMPLATE{DEFAULT_ITEM} = {
	title=>'No title',
	description=>'No content',
	guid=>'',
	pubdate=>scalar(localtime),
	author=>'',
	'link'=>'',
};	

sub rss_edit {
	my $PART = shift;
	my $text = $RSS_TEMPLATE{$PART};
	return $text unless($RSS_TEMPLATE{"DEFAULT_$PART"});
	my %config = @_ if(@_);
	foreach(keys %{$RSS_TEMPLATE{"DEFAULT_$PART"}}) {
		my $find = '####' . uc($_) . '####';
		my $rpl = $config{$_} ? $config{$_} : $RSS_TEMPLATE{"DEFAULT_$PART"}{$_};
		$rpl ||= "";
		$text =~ s/$find/$rpl/g;
	}
	return $text;
}

sub rss_start {
	return rss_edit('START',@_);
}

sub rss_end {
	return rss_edit('END',@_);
}

sub rss_item {
	my @data;
	foreach my $item (@_) {
		push @data, rss_edit('ITEM',%$item);	
	}
	return @data;
}
