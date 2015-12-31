#!/usr/bin/perl -w
package MyPlace::Data::Dumper;
use strict;
use warnings;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw(dumpdata);
    @EXPORT_OK      = qw(dumpdata);
}
use Data::Dumper;
sub dumpdata {
	my $var = shift;
	my $name = shift(@_) || '$VAR_DUMP';
	return Data::Dumper->Dump([$var],[$name]);
}
1;

