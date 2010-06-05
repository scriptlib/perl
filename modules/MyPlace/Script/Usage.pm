#!/usr/bin/perl -w
package MyPlace::Script::Usage;
use strict;
use warnings;

BEGIN {
    use Exporter ();
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT_OK      = qw(&help_required &help_even_empty &format_help &parse_arg);
}

my $default_optmsg="-h,--help:Display this text|--edit-me:Edit me";

sub parse_arg {
    my %r;
    $r{file}=shift;
    foreach(@_) {
        if($_ eq "-h" or $_ eq "--help") {
            $r{help}="true";
            last;
        }
        elsif($_ eq "--edit-me") {
            $r{edit}="true";
        }
    }
    return %r;
}
sub help_even_empty {
    my $fn=shift;
    if(@_) {
        return 1 if &help_required(@_);
        return undef;
    }
    else {
        &format_help($fn,$default_optmsg);
        return 1;
    }
}

sub help_required {
    my %r=&parse_arg(@_); 
    return undef unless($r{file});
    return undef unless(-r $r{file});
    if($r{help}) {
        &format_help($r{file},$default_optmsg);
        return 1;
    }
    if($r{edit}) {
        &edit_file($r{file});
        return 1;
    }
    return undef;
}

sub edit_file {
    system("editor",@_);
}

sub format_help {
    require MyPlace::Script::Src2Help;
    MyPlace::Script::Src2Help::print_help(@_);
}

return 1;
