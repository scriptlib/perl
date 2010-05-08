#!/usr/bin/perl -w
package Help;
use strict;


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

sub do_and_exit {
    my %r=&parse_arg(@_); 
    return undef unless($r{file});
    return undef unless(-r $r{file});
    my $amsg="-h,--help:Display this text|--edit-me:Edit me";
    if($r{help}) {
        &format_help($r{file},$amsg);
        return 1;
    }
    if($r{edit}) {
        &edit_file($r{file});
        return 1;
    }
    return undef;
}

sub edit_file {
    system("vim",@_);
}

sub format_help {
    system("formathelp",@_);
}

return 1;
