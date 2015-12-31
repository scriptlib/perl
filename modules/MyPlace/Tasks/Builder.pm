#!/usr/bin/perl -w
package MyPlace::Tasks::Builder;
use strict;
use warnings;
BEGIN {
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw();
    @EXPORT_OK      = qw();
}
use MyPlace::Script::Message;

sub new {
	my $class = shift;
	my $self = bless {@_},$class;
	$self->{defs} = {};
	$self->{tasks} = [];
	$self->{queue} = [];
	$self->{sorted} = [];
	return $self;
}

sub add {
	my $self = shift;
	my $name = shift;
	$self->{defs}->{$name} = {name=>$name,@_};
	push @{$self->{sorted}},$name;
	return;
}

sub more {
	my $self = shift;

	return 1 if(@{$self->{tasks}});
	return 1 if(@{$self->{queue}});
	
	
	my %q_defs;
	my %t_defs;
	my @queue;
	my @tasks;

	foreach my $defname (@{$self->{sorted}}) {
		$_ = $self->{defs}->{$defname};
		if($_->{queue}) {
			$q_defs{$defname} = $_;
		}
		else {
			$t_defs{$defname} = $_;
		}
	}
	@tasks = $self->collect_tasks(\%t_defs) if(%t_defs);
	@queue = $self->collect_tasks(\%q_defs) if(%q_defs);
	
	if(!(@tasks or @queue)) {
		app_warning("Tasks::Builder build NOTHING!\n");
		return undef;
	}


		$self->{queue} = [@queue];
		$self->{tasks} = [@tasks];
		app_warning("Tasks::Builder build " . (scalar(@tasks) + scalar(@queue)) . " tasks total\n");
#	push @{$self->{tasks}},$task;

#	foreach my $name (keys %{$self->{defs}}) {
#		my $def = $self->{defs}->{$name};
#		my $task = $self->new_task($name,$def);
#		if($task) {
#			app_message2 "Build tasks from [$name] $def->{description}\n";
#			if($def->{workdir}) {
#				$task->{workdir} = $def->{workdir};
#			}
#			push @{$self->{tasks}},$task;
#		}
#	}
	return 1 if(@{$self->{tasks}});
	return undef;
}

sub next {
	my $self = shift;
	if($self->{queue} and @{$self->{queue}}) {
		my @r;
		foreach(@{$self->{queue}}) {
			my $def = $self->{defs}->{$_->{def}};
			my @ta;
			push @ta,@{$def->{prefix}} if($def->{prefix});
			push @ta,@{$_->{data}} if($_->{data});
			push @ta,@{$def->{suffix}} if($def->{suffix});
			push @r,MyPlace::Tasks::Task->new(@ta);
		}
		$self->{queue} = [];
		return \@r;
	}
	return unless($self->{tasks});
	my @tasks = @{$self->{tasks}};
	my $last = $#tasks;
	my $confkey = 'Tasks::Builder::Config::LastTask';
	my $index = 
		defined $self->{LastTask} ? $self->{LastTask} :
		defined $main::MYSETTING->{$confkey} ? $main::MYSETTING->{$confkey}:
		-1;
	if($index < $last) {
		$self->{LastTask} = $index + 1;
	}
	elsif($self->{loop}) {
		$self->{LastTask} = 0;
	}
	else {
		return undef;
	}
	my $i_start = $self->{LastTask};
	my $i_end = $self->{LastTask} + 30;
	$i_end = $last if($i_end > $last);
	$self->{LastTask} = $i_end;
	my @r;
	foreach my $tidx($i_start .. $i_end) {
		my $current = $self->{tasks}->[$tidx];
		my $prefix = $self->{defs}->{$current->{def}}->{prefix} || [];
		my $data = $current->{data} || [];
		my $suffix = $self->{defs}->{$current->{def}}->{suffix} || [];
#	use Data::Dumper;
#	die(Data::Dumper->Dump([$prefix,$suffix],['*prefix','*suffix']),"\n");
		push @r,MyPlace::Tasks::Task->new(@$prefix,@$data,@$suffix);
	}
	$main::MYSETTING->{$confkey} = $self->{LastTask};
	if($i_end == $last) {
		$self->{tasks} = [];
	}
	return \@r;
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
	my @r;
	my %nodup;

	my $DATATYPE = ref($data) || '';

	if($DATATYPE eq 'CODE') {
		foreach($data->()) {
			next unless($_);
			next if(/^#/);
			next if($nodup{$_});
			push @r,_collect_data($def,$_);
			$nodup{$_} = 1;
		}
	}
	elsif($DATATYPE) {
		push @r,_collect_data($def,$_) foreach(@$data);
	}
	elsif(-f $data) {
			push @r,_collect_datafile($def,$data);
	}
	elsif($data =~ m/^file:\/\/(.+)$/) {
		push @r,_collect_datafile($def,$1);
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
			my $name = $def->{name};
			app_message2 "Collect data for [$name\] from <$data>\n";
			#print STDERR "Read from $source\n";
			open FI,'<',$data or return;
			foreach(<FI>) {
				chomp;
				next unless($_);
				next if(/^#/);
				next if($nodup{$_});
				push @r,$_;
				$nodup{$_} = 1;
			}
			close FI;
		}
	return @r;		
}

sub collect_tasks {
	my $self = shift;
	my $defs = shift;
	my %top;
	my %data;
#		use Data::Dumper;
#		print STDERR Data::Dumper->Dump([$defs],['*defs']),"\n";
	foreach my $name (@{$self->{sorted}}) {
		next unless($defs->{$name});
		my $def = $defs->{$name};
		app_message2 "Build tasks from [$name] $def->{description}\n";
		my @suffix;
		if($def->{static} and $def->{static_data}) {
			@suffix = @{$def->{static_data}};
		}
		else {
			@suffix = _collect_data($def,$def->{data});
			$def->{static_data} = \@suffix;
		}
		if(@suffix) {
			foreach my $current (@suffix) {
				my @data = split(/\s*\t\s*/,$current);
				my $key = join(":",(reverse @data),$name);
				if($def->{top}) {
					$top{$key}->{def}=$name;
					$top{$key}->{data} = \@data;
				}
				else {
					$data{$key}->{def}=$name;
					$data{$key}->{data}=\@data;
				}
			}
		}
	}
	my @tasks;
	foreach my $key(keys %top) {
		push @tasks,$top{$key};
	}
	foreach my $key(sort keys %data) {
		push @tasks,$data{$key};
	}
	return @tasks;
}



1;

