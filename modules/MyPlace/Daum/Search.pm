#!/usr/bin/perl -w
package MyPlace::Daum::Search;
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
use MyPlace::Search;
use constant {
	IMAGE_SEARCH_URL => 'http://tab.search.daum.net/dsa/search?w=xml&m=image',
}

my %DEFAULT_PARAMS = 
(
    www => {
		'Adult'=>'1',
		'AdultType'=>'1',
	},
    images => 
    {
        'Adult'=>'1',
		'AdultType'=>'1',
        'lpp'=>'60',
		'SimilarYN'=>'Y',
    },
);

my %IMAGE_TYPE_MAP = {
	'all'=>undef,
	'small'=>'1',
	'tiny'=>'1',
	'480X320'=>'1',
	'480x320'=>'1',
	'medium'=>'2',
	'640x480'=>'2',
	'640X480'=>'2',
	'large'=>'3',
	'1024X768'=>'3',
	'1024x768'=>'3',
	'xxlarge'=>'4',
	'1'=>'1',
	'2'=>'2',
	'3'=>'3',
	'4'=>'4',
}
my %PARAM_NAME = {
	'images'=> {
		'size'=>'Size',
		'page'=>'page',
		'count'=>'lpp',
		'keyword'=>'q',
	},
};

sub search_images {
	my ($self,$keyword,$page,@args) = @_;

}

&q=%C3%D6%C1%F6%C7%E2&page_offset=0&cr=&ColorByName=&ColorGroup=&Size=&DateStart=&DateEnd=&period=&ft=&SortType=tab&FaceType=&viewType=&od=&lpp=30&page=2&SearchType=tab&ResultType=tab&SimilarYN=Y


sub new {my $class = shift;return bless {@_},$class;}

1;

__END__
=pod

=head1  NAME

MyPlace::Daum::Search - PERL Module

=head1  SYNOPSIS

use MyPlace::Daum::Search;

=head1  DESCRIPTION

___DESC___

=head1  CHANGELOG

    2010-11-28 00:56  xiaoranzzz  <xiaoranzzz@myplace.hell>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@myplace.hell>


# vim:filetype=perl
