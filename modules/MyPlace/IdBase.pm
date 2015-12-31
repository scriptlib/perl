#!/usr/bin/perl -w
package MyPlace::IdBase;
use strict;
use warnings;
use MyPlace::SimpleQuery;
use File::Spec::Functions qw/catfile/;

sub new {
	my $class = shift;
	my $source = shift;
	my $dblist = shift;
	my $self = bless {source=>$source,dblist=>$dblist},$class;
	print STDERR "Initialize IdBase: $source\n";
	return $self unless($dblist);
	if(ref $dblist) {
		foreach(@$dblist) {  
			#print STDERR "\t database: $_\n";
			$self->load_db($_);
		}
	}
	else {
		#print STDERR "\t database: $_\n";
		$self->load_db($dblist);
	}
	return $self;
}


sub load_db {
	my $self = shift;
	my $dbname = shift;
	my @options;
	if(ref $dbname) {
		($dbname,@options) = @$dbname;
	}
	my $dbfile = catfile($self->{source},$dbname . ".sq");
	if(! -f $dbfile) {
		foreach my $basename ($dbname, uc($dbname), $dbname . ".sq", uc($dbname) . ".sq") {
			my $filename = $basename;
			if(-f $filename) {
				$dbfile = $filename;
				last;
			}
			$filename = catfile($self->{source},$basename);
			if(-f $filename) {
				$dbfile = $filename;
				last;
			}
			$filename = catfile($self->{source},$basename,"database.sq");
			if(-f $filename) {
				$dbfile = $filename;
				last;
			}
		}
	}
	my $db = new MyPlace::SimpleQuery;
	if(@options) {
			$db->set_options(@options);
	}
	print STDERR "\tload database [$dbname] $dbfile\n";# if($self->{VERBOSE});
	$db->feed($dbfile) if(-f $dbfile);
	$self->{db} = {} unless($self->{db});
	$self->{db}->{$dbname} = $db;
	$self->{dbinfo} = {} unless($self->{dbinfo});
	$self->{dbinfo}->{$dbname} = $dbfile;
	return $db;
}

sub get_dbinfo {
	my $self = shift;
	my $info = $self->{dbinfo};
	return %{$info};
}

sub additem {
	my $self = shift;
	my $total = 0;
	my @error;
	if($self->{db}) {
		foreach my $dbname (keys %{$self->{db}}) {
			my ($count,$msg) = $self->{db}->{$dbname}->additem(@_);
			if($count) {
				$total += $count;
				print STDERR "$count Id add to [database:$dbname]\n";
			}
			else {
				push @error,"[database:$dbname] $msg";
			}
		}
		if(@error) {
			print STDERR join("\n",@error),"\n";
		}
		return $total,join("\n",@error);
	}
	else {
		return undef,"NO database loaded"; 
	}
}
sub add {
	my $self = shift;
	my $total = 0;
	my @error;
	if($self->{db}) {
		foreach my $dbname (keys %{$self->{db}}) {
			my ($count,$msg) = $self->{db}->{$dbname}->add(@_);
			if($count) {
				$total += $count;
				print STDERR "$count Id add to [database:$dbname]\n";
			}
			else {
				push @error,"[database:$dbname] $msg";
			}
		}
		if(@error) {
			print STDERR join("\n",@error),"\n";
		}
		return $total,join("\n",@error);
	}
	else {
		return undef,"NO database loaded"; 
	}
}

sub save {
	my $self = shift;
	if($self->{db}) {
		foreach my $dbname (keys %{$self->{db}}) {
			$self->{db}->{$dbname}->saveTo($self->{dbinfo}->{$dbname});
		}
	}
	else {
		return undef,"NO database loaded"; 
	}
	
}

sub item {
	my $self = shift;
	my $idName = shift;
	my $dbname = shift;
	if(!$dbname) {
		$dbname = (keys %{$self->{db}})[0];
	}
	return $self->{db}->{$dbname}->item($idName);
}

sub query {
	my $self = shift;
	my $key = shift;
	return $self->all(@_) unless($key);
	my $dbname = shift;
	if($dbname) {
		if($self->{db}->{dbname}) {
			return $self->{db}->{dbname}->query($key);
		}
		else {
			return undef,"Database $dbname not load";
		}
	}
	elsif($self->{db}) {
		my %result;
		foreach my $dbname (keys %{$self->{db}}) {
			my ($r,@item) = $self->{db}->{$dbname}->query($key);
			if($r) {
				$result{$dbname} = [] unless($result{$dbname});
				push @{$result{$dbname}},@item;
			}
		}
		if(%result) {
			return 1,%result;
		}
		else {
			return undef,"Query $key match nothing";
		}
	}
	else {
		return undef,"NO database loaded"; 
	}
}

sub all {
	my $self = shift;
	my $dbname = shift;
	if($dbname) {
		if($self->{db}->{dbname}) {
			return $self->{db}->{dbname}->all();
		}
		else {
			return undef,"Database $dbname not load";
		}
	}
	elsif($self->{db}) {
		my %result;
		foreach my $dbname (keys %{$self->{db}}) {
			my ($r,@item) = $self->{db}->{$dbname}->all();
			if($r) {
				$result{$dbname} = \@item;
			}
		}
		if(%result) {
			return 1,%result;
		}
		else {
			return undef,"Database contains nothing";
		}
	}
	else {
		return undef,"NO database loaded"; 
	}

}

1;
__END__

