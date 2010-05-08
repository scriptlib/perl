#!/usr/bin/perl -w
package MyPlace::Script::ENV;
use strict;
use warnings;
BEGIN {
    use Exporter ();
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT_OK      = qw($TOP_DIR $SRC_DIR $BIN_DIR $MOD_DIR);
}
our $TOP_DIR=$ENV{XR_SHARE_DIR};
our $SRC_DIR=$ENV{XR_PERL_SOURCE_DIR};
our $BIN_DIR=$ENV{XR_PERL_BINARY_DIR};
our $MOD_DIR=$ENV{XR_PERL_MODULE_DIR};
return 1;
