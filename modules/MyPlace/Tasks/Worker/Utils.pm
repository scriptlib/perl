#!/usr/bin/perl -w
use MyPlace::Script::Message;
use MyPlace::Tasks::Task qw/$TASK_STATUS/;
use File::Spec::Functions qw/catdir catfile/;
use File::Glob qw/bsd_glob/;
use strict;
use warnings;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw(\$TASK_STATUS &catdir &catfile &bsd_glob &record_in_file &NEW_TASK &GET_PATH &set_workdir);
    @EXPORT_OK      = qw();
}


my %_in_file_records;
sub record_in_file {
	my $filename = shift;
	my $use_last_records = shift;
	my @items = @_;
	if(!$use_last_records) {
		if(open FI,'<',$filename) {
			while(<FI>) {
				chomp;
				next unless($_);
				$_in_file_records{$_} = 1;
			}
			close FI;
		}
	}
	my @newitem;
	foreach(@items) {
		next if($_in_file_records{$_});
		push @newitem,$_;
		$_in_file_records{$_} = 1;
	}
	if(@newitem) {
		open FO,">>",$filename;
		foreach(@newitem) {
			print FO $_,"\n";
		}
		close FO;
	}
	return @newitem;
}

sub NEW_TASK  {
	my $task = shift;
	my $newtask = new MyPlace::Tasks::Task(@_);
	foreach(qw/target_dir source_dir workdir options level/) {
		$newtask->{$_} = $task->{$_};
	}	
	return $newtask;
}

sub GET_PATH {
	my $namespace = shift;
	my $filename = shift;
	my @result;
	foreach my $type(bsd_glob("$namespace/*")) {
		$type = substr($type,length($namespace)+1);
		next if($type =~ m/^\./);
		if(-f "$namespace/$type/$filename") {
			push @result,$type;
		}
	}
	return @result;
}

sub set_workdir {
	my $wd = shift;
	return 1 unless($wd);
	if(! -d $wd) {
		mkdir $wd or return undef,"Error creating directory $wd:$!";
	}
	chdir $wd or return undef,"Error change working directory $wd:$!";
	return 1;
}
1;
