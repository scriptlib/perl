#!/usr/bin/perl -w
use strict;
use warnings;


my $source_directory;
my $target_directory;

use Cwd;
use File::Glob qw/bsd_glob/;

sub usage {
	return <<EOF
------------------------------------------------------------------
| Usage:
|	$0
|	$0 {target_directory}
|	$0 {source_directory} {target_directory}
------------------------------------------------------------------
EOF
}

foreach(@ARGV) {
	if($_ eq '-h' or $_ eq '--help') {
		die(&usage(),"\n");
	}
}

if(!@ARGV) {
	$source_directory=$0;
	$source_directory=~ s/^\.\///;
	$source_directory=~ s/\/[^\/]*$//;
	if(!$source_directory) {
		die(&usage,"\n");
	}
	else {
		$target_directory='.' #getcwd();
	}
}
elsif(@ARGV > 1) {
	($source_directory,$target_directory)=@ARGV;
}
else {
	$source_directory=$0;
	$source_directory=~ s/^\.\///;
	$source_directory=~ s/\/[^\/]*$//;
	if(!$source_directory) {
		$source_directory = ".";
	}
	$target_directory=shift(@ARGV);
	
}

print STDERR "Source directory:  $source_directory\n";
print STDERR "Target directory:  $target_directory\n\n";
if(not (-d $source_directory and -d $target_directory)) {
	print STDERR "Directory not exist.\n";
	die(&usage,"\n");
}
my @files_err;


sub create_link {
	my ($source,$target) = @_;
	$target =~ s/^\.\///;
	print STDERR "$source\n-> $target";
	return system_exec(qw/ln -sfT/,$source,$target);
}
sub create_dir {
	foreach(@_) {
		print STDERR "+ $_";
		system_exec('mkdir','-p','--',$_);
	}
}
sub copy_file {
	my ($source,$target) = @_;
	$target =~ s/^\.\///;
	print STDERR "$source\n=  $target";
	return system_exec(qw/cp -aT --/,$source,$target);
}

sub system_exec {
    #return system('echo',@_)==0;
    if(system(@_)==0) {
		print STDERR "\t[OK]\n\n";
    }
    else {
		print STDERR "\t[Failed]\n\n";
        return undef;
    }
}



sub pushing {
    my($source_directory,$target_directory,$prefix) = @_;
    foreach my $filename (bsd_glob("$source_directory/*"),bsd_glob("$source_directory/.*")) {
        if($filename =~ /\/\./) {
            print STDERR "\"$filename\" \t[Ignored]\n";
            next;
        }
        elsif($filename =~ /\/(config|local)$/) {
            unless(-d "$target_directory/$prefix$1") {
				create_dir("$target_directory/$prefix$1") 
					or push @files_err, "[mkdir] $prefix$1";
            }
            &pushing("$filename","$target_directory/$prefix$1","");
        }
        elsif($filename =~ /\/local\/(share)$/) {
            unless(-d "$target_directory/$prefix$1") {
                create_dir("$target_directory/$prefix$1")
                    or push @files_err, "[mkdir] $prefix$1";
            }
            &pushing("$filename","$target_directory/$prefix$1","");
        }
        else {
            my $basename = $filename;
            $basename =~ s/^.*\///;
            if($basename =~ m/^#(.+)$/) {
                $basename = $1;
                if(-l $filename) {
					copy_file($filename,"$target_directory/$basename")
                        or push @files_err,"[cp] $filename ->$basename";
                }
                else {
                    create_link($filename,"$target_directory/$basename")
                        or push @files_err,"[ln] $filename ->$basename";
                }
            }
            else {
                create_link($filename,"$target_directory/$prefix$basename")
                    or push @files_err,"[ln] $filename ->$basename";
            }
        }
    }
}

&pushing($source_directory,$target_directory,"");

if(@files_err) {
    print STDERR "Error occurred while processing files:\n";
    print STDERR join("\n",@files_err);
    exit 1;
}
exit 0;



 
