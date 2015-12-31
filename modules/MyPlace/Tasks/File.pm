#!/usr/bin/perl -w
package MyPlace::Tasks::File;
use strict;
use warnings;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT_OK         = qw(read_tasks write_tasks);
}

my $MODULENAME = "MyPlace::Tasks::File";

sub parse_path {
	my $dirname = shift;
	return () unless($dirname);
	$dirname =~ s/\.(?:txt|md)$//;
	return split(/(?:[\\\/]|::)/,$dirname);
}

sub write_tasks {
}

sub read_tasks {
	my $file = shift;
	my $namespace = shift;
	my $writeback = shift;
	my $as_array = shift;
	my $modified = 0;	
	if(!$file) {
		print STDERR "[$MODULENAME} Error, load nothing from nothing\n";
		return;
	}
	if(! -f $file) {
		print STDERR "[$MODULENAME] Error, file not exist: $file\n";
		return;
	}
	if(!open FI,'<',$file) {
		print STDERR "[$MODULENAME] Error opening <$file> for reading: $!\n";
		return;
	}
	my @prefix = parse_path($namespace);
	my @tasks;
	my @text;
	foreach(<FI>) {
		#print STDERR $_;
		chomp;
		s/^\s*//;
		s/\s*$//;
		if(!$_) {
			push @text,$_;
			next;
		}
		elsif(m/^\s*>/) {
			push @text,$_;
			next;
		}
		else {
			$modified = 1;
			push @text,">$_";
		}	
		my $task;
		if($as_array) {
			$task = [@prefix,split(/\s*(?:[\>\t]|\\t)\s*/,$_)];
		}
		else {
			$task = MyPlace::Tasks::Task->new(@prefix,split(/\s*(?:[\>\t]|\\t)\s*/,$_));
		}
		push @tasks,$task;
	}
	close FI;
	if($modified && $writeback) {
		if(open FO,">",$file) {
			print FO join("\n",@text);
			close FO;
		}
		else {
			print STDERR "[$MODULENAME] Error opening <$file> for writting:$!\n";
		}
	}
	if((!@tasks) and @prefix) {
		push @tasks, MyPlace::Tasks::Task->new(@prefix);
	}
	if(@tasks) {
		return \@tasks;
	}
	return undef;
}


1;


