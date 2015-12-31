#!/usr/bin/perl -w
package MyPlace::Debug::Dump;
use Data::Dumper;
use strict;
use warnings;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw(debug_dump);
    @EXPORT_OK      = qw(dump);
}



sub dumper {
	return Data::Dumper->Dump(@_);
}
sub dump {
	goto &debug_dump;
}
sub debug_dump {
	my %table;
	my $idx;
	while(@_) {
		my $ref = shift;
		my $name = shift;
		if(!$ref) {
#			$ref = ['undef'];
		}
		if(!$name) {
			$idx++;
			$name = ref $ref ? "*var$idx" : "\$var$idx";
		}
		$table{$name} = $ref;
	}
	return undef unless(%table);
	@_ = ([values %table],[keys %table]);
	goto &dumper;
}
sub dumpv {
	my %table;
	my $idx;
	foreach(@_) {
		$idx++;
		$table{"var$idx"} = $_;
	}
	return &dump(%table);
}

1;

__END__
=pod

=head1  NAME

MyPlace::Debug::Dump - PERL Module

=head1  SYNOPSIS

use MyPlace::Debug::Dump;

=head1  DESCRIPTION

___DESC___

=head1  CHANGELOG

    2012-01-25 17:15  xiaoranzzz  <xiaoranzzz@myplace.hell>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@myplace.hell>


# vim:filetype=perl

