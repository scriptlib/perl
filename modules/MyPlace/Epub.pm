package MyPlace::Epub;
use strict;

BEGIN {
    use Exporter ();
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT_OK      = qw(&get_media_type &get_file_id);
}


my %media_types = (
                '\.css$' => 'text/css',
                '\.(:?html|xhtml|xml)$' => 'application/xhtml+xml',
                '\.(:?jpg|jpeg|jpe)$' => 'image/jpeg',
                '\.png$' => 'image/png',
            );


sub get_media_type {
    my $file = shift;
    return undef unless($file);
    foreach(keys %media_types) {
        if($file =~ /$_/i) {
            return $media_types{$_};
            last;
        }
    }
    return undef;
}

sub get_file_id {
    my $file = shift;
    return undef unless($file);
    my $id = $file;
    $id =~ s/\.[^\.]+$//;
    $id =~ s/[\/\\]/-/g;
    return $id;
}

1;
