#!/usr/bin/perl -w
package MyPlace::Encode;
use strict;
use warnings;
use Encode qw//;
use Encode::Guess qw//;
use constant {MAX_TEST_LENGTH => 4096};
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT_OK      = qw(&guess_encoding);
}
sub guess_encoding {
	my ($text,$verbose,@failback) = @_;
	if(ref $text) {
		$text = join("",@{$text});
	}
	my $asc = 0;
	my $high = 0;
	print STDERR "Guessing text encoding ,with sample length = ",MAX_TEST_LENGTH,":\n" if($verbose);
	$text = substr($text,0,MAX_TEST_LENGTH);
	my @bytes = map ord,split("",$text);
	foreach(@bytes) {
		if($_ <= 127) {
			$asc++;
		}
		else {
			$high++;
		}
	}
	print STDERR "***Got [7Bit]:$asc,[8Bit]:$high***" if($verbose);
	my $enc;
	if(!$high) {
		$enc=Encode::find_encoding('ascii');
	}
	elsif($high <$asc) {
		$enc=Encode::find_encoding('iso-8859-1');
	}
	else {
		$enc = Encode::Guess::guess_encoding($text,'utf8','gb2312');
	}
	$enc = Encode::Guess::guess_encoding($text,@failback) unless(ref $enc);
	if($verbose) {
		if(ref $enc) {
			print STDERR ", should be [",$enc->name,"]\n";
		}
		else {
			print STDERR ", failed to tell\n";
		}
	}
	return $enc;
}
1;
