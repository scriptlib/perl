

package MyPlace::SimpleQuery;
use strict;
use File::Spec::Functions qw/catfile catdir/;

sub new {
	my $class = shift;
	my $self = bless {},$class;
	$self->{OUTPUT} = [];
	if(@_) {
		push @{$self->{OUTPUT}},@_;
	}
	$self->{database} = "TEXT INPUT";
	$self->{options} = {};
	return $self;
}

sub set_options {
	my $self = shift;
	$self->{options} = {%{$self->{options}},@_};#->{$_} = 1 foreach(@_);
	return $self;
}

sub _include_file {
	my $self = shift;
	my $filename = shift;
	my $absfile = $filename;
	print STDERR "#INCLUDE $filename\n";
	if(!$self->{input}) {
	}
	elsif($filename =~ m/^\//) {
	}
	else {
		my $rel = $self->{input};
		$rel =~ s/\/[^\/]+$/\//;
		$absfile = $rel . $filename;
	}
	if(-f $absfile) {
		my $newsq = new MyPlace::SimpleQuery;
		$newsq->feed($absfile,'file');
		return $newsq;
	}
	return;
}

sub _parse_from_file {
	my $self = shift;
	my $input = shift;
	$self->{input} = $input;
	my @lines;
	open FI,'<',$input or return undef,"$!, while opening $input";
	@lines = <FI>;
	close FI;
	return $self->_parse_from_text(@lines);
}

sub _parse_from_text {
	my $self = shift;
	my %info;
	my @sortedId;
	my @text = @_;
	while(@text) {
		local $_ = shift(@text);
		chomp;
		s/^\s+//;
		s/\s+$//;
		if(!$_) {
			push @sortedId,'';
			next;
		}
		#print STDERR "TEXT:[$_]\n";
		if(m/^\s*\#OUTPUT\s*:\s*(.+?)\s*$/) {
			push @{$self->{OUTPUT}},$1;
			push @sortedId,$_;
			next;
		}
		if(m/^\s*\#INCLUDE\s*:\s*(.+?)\s*$/) {
			push @sortedId,$_;
			my $newsq = $self->_include_file($1);
			push @{$self->{INCLUDE}},$newsq;
			my $ninfo = $newsq->{info};
			if($ninfo and ref $ninfo and %$ninfo) {
				%info = (%info,%$ninfo);
#				$self->{external_info} = $ninfo;
			}
			next;
		}
		my @va = split(/\s*\t\s*/,$_);
		my $k = shift(@va);
		my $c = scalar(@va);
		my $v;
		if($c >= 1) {
			$v = [@va];
		}
		elsif($k =~ m/^([^\s]+)\s+([^\s]+)$/) {
			$k = $1;
			$v = [$2];
		}
		else {
			$v = [""];
		}
		push @sortedId,$k unless(defined $info{$k});
		$info{$k} = $v;
	}
	#die();
	if(!@sortedId) {
		return undef,"Invalid data feed";
	}
	return {
		info=>\%info,
		sortedId=>\@sortedId,
	};
}

sub item {
	my $self = shift;
	my $strict = 1;
	return $self->find_item($strict,@_);
}

sub find_items {
	my $self = shift;
	my @result;
	foreach my $idName(@_) {
		my($status,@r) = $self->find_item(undef,$idName);
		if($status) {
			push @result,@r;
		}
	}
	if(@result) {
		return 1,@result;
	}
	else {
		return undef,'Nothing found';
	}

}
sub output_item {
	my $self = shift;
	my $ids = shift;
	my $info = shift;
	my @formats = @{$self->{OUTPUT}};
	@formats = ('${KEY}','${VALUE}') unless(@formats);
	my @translater;
	my %DATA_INDEX = (
		ID=>0,
		KEY=>0,
		VALUE=>1,
		NAME=>1,
		VALUES=>2,
	);
	foreach my $fmt (@formats) {
		my @t = ($fmt);
		while($fmt =~ m/\$\{(ID|KEY|VALUE|VALUES|NAME)\s*:\s*(.+?)\s*=>\s*(.*?)\s*\}/g) {
			my $t = {};
			$t->{key} = $1;
			$t->{data} = $DATA_INDEX{$1};
			$t->{exp} = $2;
			$t->{rpl} = $3 || '';
			push @t,$t;
		}
		while($fmt =~ m/\$\{\s*(ID|KEY|VALUE|VALUES|NAME)\}/g){
			push @t,{
				key=>$1,
				data=>$DATA_INDEX{$1},
			}
		}
		push @translater,\@t;
	}
	#use MyPlace::Debug::Dump;print STDERR debug_dump(\@translater),"\n";
	my @result;
	foreach my $key (@$ids) {
		next unless($key);
		my @values = @{$info->{$key}};
		my $value = $values[0];
		my $values = join(",",@values);
		my @item = ($key,$value);
		foreach my $gt (@translater) {
			my @gt = @$gt;
			my $fmt = shift(@gt);
			my $output = $fmt;
			foreach my $t(@gt) {
				my $data = [$key,$value,$values]->[$t->{data}];
				if($t->{exp}) {
					$output =~ s/\$\{$t->{key}\s*:\s*.+?\s*=>\s*.*?\s*\}/$data/g;
					$output =~ s/$t->{exp}/$t->{rpl}/g;
				}
				else {
					$output =~ s/\$\{$t->{key}\}/$data/g;
				}
			}
			push @item,$output;
		}
		push @result,\@item;
	}
	return @result;
}
sub find_item {
	my $self = shift;
	my $strict = shift;

	my $idName = shift;

	my %table = %{$self->{info}};
	my $target;
	my @match;

	foreach my $id(keys %table) {
		if($id eq $idName) {
			push @match,$id;
			last;
		}
	}
	if(!@match) {
		foreach my $id(keys %table) {
			foreach my $name(@{$table{$id}}) {
				if($name eq $idName) {
					push @match,$id;
					last;
				}
			}
			last if($strict and @match);
		}
	}
	if(!@match) {
		return undef,"[$idName] match no item";
	}

	my @result = $self->output_item(\@match,\%table);

	if($strict) {
		return @{$result[0]};
	}
	return 1,@result;
}

sub additem {
	my $self = shift;
	my $key = shift;
	my $value = (@_ ? [@_] : [""]);
	#shift(@_) || "";
	if(!$key) {
		return undef,"Empty key not allowed";
	}
	return $self->_add({
			info=>{$key=>$value},
			sortedId=>[$key]
	});
}

sub add {
	my $self = shift;
	my ($r,$msg) = $self->_parse_from_text(@_);
	if(!$r) {
		return undef,"Invalid input: $msg";
	}
	return $self->_add($r);
}

sub _add {
	my $self = shift;
	my $r = shift;

	my %info = ();
	my @sorted = ();
	if($self->{info}) {
		%info = %{$self->{info}};
		@sorted = @{$self->{sortedId}};
	};
	my %incoming = %{$r->{info}};
	my @id = @{$r->{sortedId}};
	my $count;
	foreach my $id(@id) {
		if($id =~ m/^\s*$/) {
			next;
		}
		#	elsif($id =~ m/^#/) {
		#	next;
		#}
		elsif(defined $info{$id}) {
			if($self->{options}->{overwrite}) {
				$count++;
				print STDERR "$id: @{$info{$id}} => @{$incoming{$id}}\n";
				$info{$id} = $incoming{$id};
			}
			else {
				print STDERR "\tKey <$id> already defined as : " . (join(" ",@{$info{$id}}) || "[EMPTY]") . "\n";
			}
			next;
		}
		#elsif(defined $info{"#$id"}) {
		#	next;
		#}
		elsif(defined $incoming{$id}) {
			$count++;
			$info{$id} = $incoming{$id};
			push @sorted,$id;
			print STDERR "\tAdd $id => @{$incoming{$id}}\n";
		}
		else {
			$count++;
			print STDERR "\tAdd $id\n";
			push @sorted,$id;
		}
	}
	$self->{info} = \%info;
	$self->{sortedId} = \@sorted;
	return $count,'ID already exist in database';
}

sub saveTo {
	my $self = shift;
	my $output = shift;
	my $comment = shift;
	if(!$self->{info}) {
		return undef,"No id to save";
	}
	open FO,">",$output or return undef,"$!, while writting $output";
	#foreach my $fmt (@{$self->{OUTPUT}}) {
	#	print FO "#OUTPUT: $fmt\n";
	#}
	foreach my $id (@{$self->{sortedId}}) {
		#	my $value = $self->{info}->{$id};
		#next unless($value);
		#if($value eq 'TRUE') {
		#	print FO $id,"\n";
		#}
		if(!$id) {
			print FO "\n";
		}
		elsif($self->{info}->{$id} && @{$self->{info}->{$id}}) {
			print FO $id,"\t",join("\t",@{$self->{info}->{$id}}),"\n";
		}
		else {
			print FO $id,"\n";
		}
	}
	print FO "#$comment\n" if($comment);
	close FO;
	return 1;
}


sub feed {
	my $self = shift;
	my $data = shift;
	my $type = shift(@_) || "";
	if(!$data) {
		if($self->{data}) {
			$data = $self->{data};
		}
		else {
			return undef,"No data supplied";
		}
	}
	my ($r,$msg);
	if(ref $data && $data->{info} && $data->{sortedId}) {
		$r = $data;
	}
	elsif($type eq 'file' or -f $data) {
		$self->{database} = $data;
		($r,$msg) = $self->_parse_from_file($data);
	}
	else {
		($r,$msg) = $self->_parse_from_text($data);
	}
	#use Data::Dumper;die(Data::Dumper->Dump([$r],[qw/$r/]));
	if($r) {
		$self->{info} = $r->{info};
		$self->{sortedId} = $r->{sortedId};
	}
	return undef,$msg unless($self->{info} && $self->{sortedId});
	return $r;
}

sub all {
	my $self = shift;
	return $self->query();
}

sub query {
	my $self = shift;
	my %target;
	my @Id;
	my %info = ();
	my @sortedId = ();
	if($self->{info}) {
		%info = %{$self->{info}};
		@sortedId = @{$self->{sortedId}};
	}
	if(@_) {
	#my $utf8 = find_encoding("utf-8");
	#map $_=$utf8->decode($_),@_;
		my @keys = grep(!/^\s*#/,keys %info);
		QUERY:foreach my $r(@_) {
			foreach my $key (@keys) {
				if($r eq $key) {
					push @Id,$key unless($target{$key});
					$target{$key} = $info{$key};
					next QUERY;
				}
			}
			my $matched = 0;
			foreach my $key (@keys) {
				foreach my $v(@{$info{$key}}) {
					if($r eq $v) {
						push @Id,$key unless($target{$key});
						$target{$key} = $info{$key};
						$matched = 1;
						last;
					}
				}
			}
			next QUERY if($matched);

			foreach my $key (@keys) {
				my $expr = $r;
				if($expr =~ m/^\/(.+)\/$/) {
					$expr = $1;
				}
				if($key =~ m/$expr/) {
					push @Id,$key unless($target{$key});
					$target{$key} = $info{$key};
				}
			}
			foreach my $key (@keys) {
				my $expr = $r;
				if($expr =~ m/^\/(.+)\/$/) {
					$expr = $1;
				}
				foreach my $v(@{$info{$key}}) {
					if($v =~ m/$expr/) {
						push @Id,$key unless($target{$key});
						$target{$key} = $info{$key};
						last;
					}
				}	
			}
			foreach my $key (@keys) {
				next if($target{$key});
				my $exp = join("|",$key,@{$info{$key}});
				if($r =~ m/^(?:$exp)\s+/ or $r =~ m/\s+(?:$exp)$/) {
					push @Id,$key;
					$target{$key} = $info{$key};
					$matched = 1;
					next QUERY;
				}
			}
			#if(!$matched) {
			#	print STDERR "Query [$r] match nothing in database ($self->{database})","\n";
			#	next QUERY;
			#}
		}
		return undef,"Query [@_] match nothing in database ($self->{database})" unless(@Id);
	}
	else {
		%target = %info;
		@Id = grep(!/^\s*#/,@sortedId);
	}
	my @result = $self->output_item(\@Id,\%target);

	return 1,@result;
}

1;

__END__
