#!/usr/bin/perl -w
package MyPlace::Filename;
BEGIN {
    use Exporter ();
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw(&get_filename &get_basename &get_fullname &get_parent &get_extname);
    @EXPORT_OK      = qw(&get_uniqname);
}

sub get_extname($) {
    my $fn=shift;
    $fn =~ s/^.*(\.[^\.]*$)/$1/;
    return $fn;
}

sub get_filename($) {
    my $fn=shift;
    $fn =~ s{\/+$}{};
    $fn =~ s{^.*\/}{}g;
    return $fn;
}

sub get_basename($) {
	my $unknow = shift;
    my $fn=&get_filename($unknow);
	return $fn if(-d $unknow);
    $fn =~ s/\.[^\.]*$//;
    return $fn;
}

sub get_fullname($) {
    my $PWD=$ENV{PWD} || $ENV{CD};
    my $fn=shift;
    return $fn if($fn =~ m{^\/});
    $fn =~ s{^\.\/}{};
    return $PWD . "\/" . $fn;    
}

sub get_parent($) {
    my $fn=&get_fullname(shift);
    $fn =~ s{\/+$}{};
    $fn =~ s{\/[^\/]*$}{};
    return $fn;
}

sub get_uniqname {
    my $base = shift;
    my $ext = shift;
    $base = "" unless($base);
	if((!$ext) and $base =~ m/^(.*)(\.[^\.]*)$/) {
		$base = $1;
		$ext = $2;
	}
    $ext = "" unless($ext);
    return "$base$ext" unless("$base$ext" eq "" or -f "$base$ext");
    my $idx = 1;
    while(-f "$base$idx$ext") {
        $idx++;
    }
    return "$base$idx$ext";
}
return 1;
