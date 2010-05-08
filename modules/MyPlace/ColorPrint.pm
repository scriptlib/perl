#!/usr/bin/perl
package MyPlace::ColorPrint;
use Term::ANSIColor;
BEGIN {
    use Exporter ();
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw(&color_print &app_message &app_error &app_warning &app_abort &color);
}


my $id = $0;
$id =~ s/^.*\///g;
my $prefix="$id> ";

sub color_print($$@) {
    my $out=shift;
    my $ref=ref $out ? $out : \$out;
    if(!((ref $ref) eq "GLOB")) {
        $ref=*STDERR;
        unshift @_,$out;
    }
    my $color=shift;
    print $ref color($color),@_,color('reset') if(@_);
}

sub app_error {
    print STDERR $prefix;
    color_print *STDERR,'red',@_;
}

sub app_message {
    print STDERR $prefix;
    color_print *STDERR,'green',@_;
}

sub app_warning {
    print STDERR $prefix;
    color_print *STDERR,'yellow',@_;
}

sub app_abort {
    &app_error(@_);
    exit $?;
}
