package MyPlace::Tasks::Utils;
use strict;
use warnings;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT_OK         = qw(strtime);
}

sub strtime {
	my $time =  shift(@_) || time();
	my $style = shift;
	my $sep1 = shift(@_); 
	my $sep2 = shift(@_);
	my $sep3 = shift(@_);
	$sep1 = "/" unless(defined $sep1); #seperator for date (year/month/day)
	$sep2 = ":" unless(defined $sep2); #seperator for time (hour::minute::second)
	$sep3 = " " unless(defined $sep3); #seperator seperated date and time
	my @r = localtime($time);
	my $year   = $r[5] + 1900;
	my $month  = $r[4]  > 9  ? ($r[4] + 1) : '0' . ($r[4]+1);
	my $day    = $r[3] > 9 ? $r[3] : '0' . $r[3];
	my $hour   = $r[2] > 9 ? $r[2] : '0' . $r[2];
	my $minute = $r[1] > 9 ? $r[1] : '0' . $r[1];
	my $second = $r[0] > 9 ? $r[0] : '0' . $r[0];
	my $clock = "$hour$sep2$minute$sep2$second";
	if((!$style) or ($style == 4)) {
		return "$year$sep1$month$sep1$day$sep3$clock";
	}
	elsif($style == 3) {
		return "$month$sep1$day$sep3$clock";
	}
	elsif($style == 2) {
		return "$day $clock";
	}
	elsif($style == 1) {
		return $clock;
	}
	elsif($style == -1) {
		return "$year$sep1$month$sep1$day";
	}
	elsif($style == -2) {
		return "$month$sep1$day";
	}
	else {
		return "$year$sep1$month$sep1$day$sep3$clock";
	}
}

1;

