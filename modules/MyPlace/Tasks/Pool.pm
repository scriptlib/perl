#!/usr/bin/perl -w
package MyPlace::Tasks::Pool;
use strict;
use warnings;
use MyPlace::Tasks::Task;
use MyPlace::Script::Message;

sub new {
	my $class = shift;
	my $name = shift;
	my $self = bless {name=>$name,@_},$class;
	$self->{tasks} = [];
	return $self;
}

sub more {
	my $self = shift;
	my $confkey = 'Tasks::Pool::Position::' . $self->{name};
	$confkey =~ s/\s+/_/g;

	if(@{$self->{tasks}}) {
		if($self->{queue}) {
			my @r = @{$self->{tasks}};
			$self->{tasks} = [];
			return @r;
		}
		else {
			my $left = @{$self->{tasks}};
			$left = $left > 10 ? 10 : $left;
			$self->{position} = $self->{position} + $left;
			$main::MYSETTING->{$confkey} = $self->{position};
			my @queue;
			foreach(1 .. $left) {
				push @queue,shift(@{$self->{tasks}});
			}	
			return @queue;
		}
	}
	if(defined $self->{MORE}) {
		$self->{MORE} += 1;
		if($self->{freq} and ($self->{MORE} <= $self->{freq})) {
			return;
		}	
	}
	$self->{MORE} = 1;
	my @tasks = $self->collect_tasks;
	my $count = scalar(@tasks);
	app_warning("Tasks::Pool [" . $self->{name} . "] build $count tasks total\n");
	my $index;
	if($self->{restorable}) {
		$self->{restorable} = 0;
		$index = $main::MYSETTING->{$confkey} || 0;
		$self->{position} = $index;
		if($index) {
			@tasks = @tasks[$index .. $count];
		}
	}
	else {
		$self->{position} = 0;
		$main::MYSETTING->{$confkey} = $self->{position};
	}
	if(@tasks) {
		if(defined $self->{level}) {
			foreach(@tasks) {
				$_->{level} = $self->{level};
			}
		}
		$self->{tasks} = [@tasks];
		$self->{MORE} = $self->{MORE} - scalar(@tasks);
		return $self->more();
	}
	else {
		return;
	}
}

sub _parse_data {
	my $def = shift;
	my $data  = shift;
	if($def->{parser}) {
		my @parser = (@{$def->{parser}});
		my $exp = shift(@parser);
		if($data =~ m/$exp/) {
			my @r;
			foreach(@parser) {
				if($_ == 1) {
					push @r,$1;
				}
				elsif($_ == 2) {
					push @r,$2;
				}
				elsif($_ == 3) {
					push @r,$3;
				}
				elsif($_ == 4) {
					push @r,$4;
				}
				elsif($_ == 5) {
					push @r,$5;
				}
				elsif($_ == 6) {
					push @r,$6;
				}
			}
			return \@r;
		}
		return undef;
	}
	else {
		return $data;
	}
}

sub _collect_data {
	my $def = shift;
	my $data = shift;
	my $no_recursive = shift;
	my @r;
	my %nodup;

	my $DATATYPE = ref($data) || '';

	if($DATATYPE eq 'CODE') {
		foreach($data->()) {
			next unless($_);
			if(ref $_) {
			}
			else {
				#next if(/^#/);
				next if($nodup{$_});
			}
			push @r,_collect_data($def,$_,1);
			$nodup{$_} = 1;
		}
	}
	elsif($DATATYPE eq 'HASH') {
		foreach(keys %$data) {
			my @prefix = split(/[\/\t]/,$_);
			my @contents = _collect_data($def,$data->{$_},1);
			if(@contents) {
				foreach my $item (@contents) {
					if(ref $item) {
						push @r,[@prefix,@$item];
					}
					else {
						push @r,[@prefix,$item];
					}
				}
			}
		}
	}
	elsif($DATATYPE) {
		if($no_recursive) {
			push @r,$data;
		}
		else {
			push @r,_collect_data($def,$_,1) foreach(@$data);
		}	
	}
	elsif(-f $data) {
			push @r,_collect_datafile($def,$data);
	}
	elsif($data =~ m/^file:\/\/(.+)$/) {
		push @r,_collect_datafile($def,$1);
	}
	elsif($def->{ignore} and $data =~ m/$def->{ignore}/) {
	}
	elsif($data =~ m/\t/) {
		push @r,[split(/\s*\t\s*/,$data)];
	}
	else {
		push @r,$data;
	}
	return @r;
}
sub _collect_datafile {
	my $def = shift;
	my $data = shift;
	my %nodup;
	my @r;
		if(-f $data) {
			my $count = 0;
			my $name = $def->{name};
			#print STDERR "Read from $source\n";
			open FI,'<',$data or return;
			foreach(<FI>) {
				chomp;
				next unless($_);
				if($def->{ignore}) {
					next if($_ =~ m/$def->{ignore}/);
				}
				else {
					next if(/^#/);
				}
				next if($nodup{$_});
				$count++;
				if(m/\t/) {
					push @r,[split(/\s*\t\s*/,$_)];
				}
				else {
					push @r,$_;
				}
				$nodup{$_} = 1;
			}
			close FI;
			app_message2 "Collect $count items for [$name\] from <$data>\n";
		}
	return @r;		
}

sub collect_tasks {
	my $def = shift;
	app_message2 "Build tasks from [" . $def->{name} . "]\n";
	my @prefix = $def->{prefix} ? @{$def->{prefix}} : ();
	my @suffix = $def->{suffix} ? @{$def->{suffix}} : ();
	my @data = _collect_data($def,$def->{data});
	my @tasks;
	if(@data) {
		foreach my $current (@data) {
			my $tn;
			if(ref $current) {
				$tn = MyPlace::Tasks::Task->new(@prefix,@$current,@suffix);
			}
			else {
				$tn = MyPlace::Tasks::Task->new(@prefix,split(/\s*\t\s*/,$current,@suffix));
			}
			$tn->{options} = {%{$def->{options}}} if($def->{options});
			push @tasks,$tn;
		}
	}
	return @tasks;
}



1;

