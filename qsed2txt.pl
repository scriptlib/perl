#!/usr/bin/perl -w
# $Id$
package MyPlace::Script::qsed2txt;
use strict;

our $VERSION = 'v0.1';
my @OPTIONS = qw/
	help|h|? 
	manual|man
/;
my %OPTS;
if(@ARGV)
{
    require Getopt::Long;
    Getopt::Long::GetOptions(\%OPTS,@OPTIONS);
}
else {
	$OPTS{'help'} = 1;
}
if($OPTS{'help'} or $OPTS{'manual'}) {
	exit &usage;
}

use File::Spec::Functions qw/catfile catdir/;
use Cwd qw/getcwd/;
my $URI_FILE_EXT = '.uri.txt';

sub usage {
	require Pod::Usage;
	my $v = $OPTS{'help'} ? 1 : 2;
	Pod::Usage::pod2usage(-exitval=>$v,-verbose=>$v);
    return  $v;
}

sub basename {
	my $filename = shift;
	my $basename = $filename;
	$basename =~ s/[\/\\]+$//;
	$basename =~ s/.*\///;
	return $basename ? $basename : $filename;
}

sub error {
	my $action = shift;
	my $msg  = shift;
	print STDERR join(":",$action,$msg),"\n";
	return undef;
}

sub parse_filename {
	my $filename = shift;
	if($filename =~ m/^(.*)[\/\\]([^\/\\]+)\.([^\.]+)$/) {
		return $1,$2,$3;
	}
	elsif($filename =~ m/^([^\/\\]+)\.([^\.]+)$/) {
		return undef,$1,$2;
	}
	else {
		return undef,$filename,undef;
	}
}

sub read_qsed {
	my $filename = shift;
	my $basename = shift;
	open my $FI,"<",$filename or return error("Opening $filename for reading","$!");
	my @links;
	my $text = join("",<$FI>);
	while($text =~ m/(?:link|href)\s*=\s*["']([^"']+)/gi) {
		push @links,$1;
	}
	close $FI;
	if(@links) {
		return $basename . "\n" . "\t" . join("\n\t",@links);
	}
	else {
		return $basename . "\n" . "\t" . join("\n\t",split(/[\r\n]+/,$text));
	}
}

sub clean_name {
	my $what = shift;
	return "" unless($what);
	$what =~ s/\.(?:rmvb|mkv|avi|rm|mpeg|mpg|flv|mov|mp4|3gp)$//gi;
	$what =~ s/[-_ ]?(?:QMVQMV|QMV|第\d+集|CD\d+)$//gi;
	$what =~ s/[-_ ]?(?:0\d|\d|[AB])$//gi;
	return $what;
}

use File::Glob qw/bsd_glob/;
sub process_dir {
	my $srcd = shift;
	my $dstd = shift;
	my $pdir = shift;
	my $wd = shift;
	my $max_level = shift;
	my $cur_level = shift(@_) || 1;

	my @files;
	$srcd =~ s/[\/\\]+$//;
	$dstd =~ s/[\/\\]+$//;
	$pdir =~ s/[\/\\]+$//;
	$wd =~ s/[\/\\]+$//;
	my $dir = $wd ? catdir($srcd,$wd) : $srcd;
	print STDERR "Processing <$dir>\n";
	my $IS_CATALOG = 0;
	foreach my $file(bsd_glob($dir . "/*")) {
		if(-d $file) {
			if($max_level and $cur_level > $max_level) {
				print STDERR "Ignored $file, MAX_LEVEL[$max_level] limited\n";
				next;
			}
			my $name = basename($file);
			my $pre = $wd ? catdir($wd,$name) : $name;
			print STDERR "\tEntering $file\n";
			process_dir($srcd,$dstd,$wd,$pre,$max_level,$cur_level+1);
			$IS_CATALOG = 1;
		}
		elsif(-f $file) {
			push @files,$file;
		}
		else {
			print STDERR "Invalid file type:$file\n";
		}
	}
	return unless(@files);
	my $FO;
	my $output = catfile($dstd,clean_name($wd) . "$URI_FILE_EXT");

	my $odir = $pdir ? catdir($dstd,clean_name($pdir)) : $dstd;
	my $wdir = $wd ? catdir($dstd,clean_name($wd)) : $dstd;
	
	system("mkdir","-p","-v","--",$odir) unless(-d $odir);
	if((!$IS_CATALOG) and $wd) {
		if($wd =~ m/^#[^\/]+\/?$/ or $wd =~ m/\/#[^\/]+\/?$/) {
			$IS_CATALOG = 1;
		}
		else {
			print STDERR  "[Writting] $output\n";
			open $FO,'>>',$output or return error("Opeing $output for writting", "$!");
		}
	}
	foreach my $file(@files) {
		my(undef,$basename,$extname) = parse_filename($file);
		$basename =~ s/\.(?:qsed|bdhd|ed2k|thunder)$//i;
		my $clean_name = $basename; $clean_name = clean_name($basename);
		my $IS_QSED;
		my $IS_IMAGES;
		if($extname =~ m/^(?:qsed|ed2k|bdhd|thunder)$/i) {
			$IS_QSED = 1;
		}
		elsif($extname =~ m/^(?:jpg|jpeg|gif|png|jpe)$/i) {
			$IS_IMAGES = 1;
		}
		else {
			print STDERR "Ignored, unknown file type for $file\n";
			next;
		}
		if($FO) {
			if($IS_QSED) {
				print STDERR  "[Appending] $output\n";
				print $FO &read_qsed($file,$basename),"\n";
			}
			else {
				my $fout = catfile($odir,$clean_name . "." . lc($extname));
				print STDERR  "[Coping] $fout\n";
				system("cp","-a","--",$file,$fout);
			}
		}
		else {
			if($IS_QSED) {
				my $fout = catfile($wdir,"$clean_name$URI_FILE_EXT");
				print STDERR "[Writting] $fout\n";
				open my $FH,">>",$fout or error("Opeing $fout for writting","$!");
				print $FH &read_qsed($file,$basename),"\n";
				close $FH;
			}
			else {
				my $fout = catfile($wdir,$clean_name . "." .  lc($extname));
				print STDERR "[Coping] $fout\n";
				system("cp","-a","--",$file,$fout);
			}
		}
	}
	close $FO if($FO);
	return 1;
}

sub process {
	my $srcd = shift;
	my $dstd = shift;
	if(! -d $dstd) {
		system('mkdir','-p','-v','--',$dstd) == 0 or return error("Creating directory $dstd",$!);
	}
	process_dir($srcd,$dstd,"","");
}

my $SOURCE = shift;
my $DEST = shift;
exit &usage if(!$DEST);
exit &usage if(!$SOURCE);
if(! -d $SOURCE) {
	exit error("Directory not exist",$SOURCE);
}
exit process($SOURCE,$DEST);




__END__

=pod

=head1  NAME

qsed2txt - Converter convert  *.qsed file to *.uri.txt

=head1  SYNOPSIS

qsed2txt [options] source_directory destination_directory

=head1  OPTIONS

=over 12

=item B<--version>

Print version infomation.

=item B<-h>,B<--help>

Print a brief help message and exits.

=item B<--manual>,B<--man>

View application manual

=item B<--edit-me>

Invoke 'editor' against the source

=back

=head1  DESCRIPTION

___DESC___

=head1  CHANGELOG

    2015-05-20 23:59  xiaoranzzz  <xiaoranzzz@MyPlace>
        
        * file created.

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@MyPlace>

=cut

#       vim:filetype=perl
