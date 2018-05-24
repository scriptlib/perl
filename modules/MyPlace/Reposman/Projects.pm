#!/usr/bin/perl -w
package MyPlace::Reposman::Projects;
use strict;
use warnings;

sub new {
	my $class = shift;
	return bless {
		'config'=>{},
		'maps'=>{},
		'hosts'=>{},
		'projects'=>{},
		'data'=>{},
		@_
		},$class;
	}
sub get_raw {
	return $_[0]->{data};
}
sub get_config {
	my $self = shift;
	return $self->{config};
}
sub get_maps {
	my $self = shift;
	return $self->{maps};
}
sub get_hosts {
	my $self = shift;
	return $self->{hosts};
}
sub get_projects {
	my $self = shift;
	return $self->{projects};
}
sub get_repos {
	my $self = shift;
	if($self->{repos}) {
		return $self->{repos};
	}
	my $projects = $self->{projects};
	my %repos;
	foreach(keys %{$projects}) {
		$repos{$_} = $self->new_repo($_,$projects->{$_});
		
	}
	$self->{repos} = \%repos;
	return \%repos;
}

sub get_names {
	my $self = shift;
	my $projects = $self->get_projects();
	return keys %{$projects};
}

sub parse_query {
	my $query = shift;
	if($query =~ m/^([^:]+):(.*)$/) {
		return $1,$2;
	}
	else {
		return $query;
	}
}

sub modify_repo_target {
	my $repo = shift;
	my $target = shift;
	return $repo unless($target);
	$repo->{_target} = $repo->{target};
	if($target =~ m/\/$/) {
		$target .= $repo->{name};
	}
	$repo->{target} = $target;
	return $repo;
}

sub query_repos {
	my $self = shift;
	my @query = @_;
	my $projects = $self->{projects};
	my @names;
	my @repos;
	foreach my $query (@query) {
		my ($exp,$target) = parse_query($query);
		next unless($exp);
		my $found;
		foreach(keys %{$projects}) {
			if(($exp eq $_) || ($projects->{$_}->{name} eq $exp)) {
				push @names,[$_,$target];
				$found = 1;
				last;
			}
		}
		next if($found);
		foreach(keys %{$projects}) {
			if(($_ =~ m/$exp/) || ($projects->{$_}->{name} =~ m/$exp/)) {
				push @names, [$_,$target];
				$found = 1;
			}
		}
	}	
	if($self->{repos}) {
		foreach(@names) {
			my $repo = $self->{repos}->{$_->[0]};
			if($repo) {
				$repo = modify_repo_target($repo,$_->[1]);
				push @repos,$repo;
			}
		}
	}
	else {
		foreach(@names) {
			my $repo = $self->new_repo($_->[0],$projects->{$_->[0]});
			if($repo) {
				$repo = modify_repo_target($repo,$_->[1]);
				push @repos,$repo;
			}

		}
	}
	return @repos;
}


sub from_file {
	my $self = shift;
	my $file = shift;
	open FI,'<',$file or return undef;
	my @data = <FI>;
	close FI;
	return $self->from_strings(@data);
}

sub from_strings {
	my $self = shift;
	my %CONFIG;
	my %MAPS;
	my %HOSTS;
	my %PROJECTS;
	require MyPlace::IniExt;
	my %DATA = MyPlace::IniExt::parse_strings(@_);
	no warnings;
	my $config_key = $MyPlace::IniExt::DEFINITION;
	foreach(keys %DATA) {
		if($_ eq $config_key) {
			#foreach my $key (keys %{$DATA{$_}}) {
			#	$CONFIG{$key} = $DATA{$_}->{$key};
			#}
			%CONFIG = (%CONFIG,%{$DATA{$_}});
		}
		elsif($_ =~ m/^host\.(.+)$/) {
			$HOSTS{$1} = $DATA{$_};
			$HOSTS{$1}->{name} = $1;
		}
		elsif($_ =~ m/^map\.(.+)$/) {
			$MAPS{$1} = $DATA{$_};
		}
		elsif($_ =~ m/^type\.(.+)$/) {
			$CONFIG{$1} = $DATA{$_};
		}
		else {
			$PROJECTS{$_} = $DATA{$_};
			$PROJECTS{$_}->{name} = $_ unless($PROJECTS{$_}->{name});
		}
	}
	#if(%MAPS) {
	#	foreach (keys %MAPS) {
	#		$CONFIG{$_}->{maps} = $MAPS{$_};
	#	}
	#}
	$self->{data} = \%DATA;
	$self->{config} = \%CONFIG;
	$self->{maps} = \%MAPS;
	$self->{hosts} = \%HOSTS;
	$self->{projects} = \%PROJECTS;
	$self->{repos} = undef;
	return \%CONFIG,\%MAPS,\%HOSTS,\%PROJECTS;
}

sub translate_url {
    my $url = shift;
    my $names = shift;
	my $id = shift;
	my $root;
	my $leaf;
	my $path;
#	print STDERR "Translate from $url\n";	
	if($names->{fullname}) {
		$path = $names->{fullname};
	}
	elsif(index($url,'#1-#2')>=0 
	   or index($url,'#1.#2')>=0
	   or index($url,'#1_#2')>=0) {
		if($names->{group} and ($names->{group} eq $names->{name})) {
			$path = $names->{name};
		}
		elsif($names->{group}) {
			$path = $names->{group} . '/' . $names->{name};
		}
		else {
			$path = $names->{name};
		}
		
	}
	elsif(index($url,'#1')>=0 and index($url,'#2')>=0) {
		$path = $names->{name};
		$path = $names->{group} . '/' . $path if($names->{group});
	}
	elsif($names->{group}) {
		$path = $names->{group} . '-' . $names->{name};
	}
	else {
		$path = $names->{name};
	}
	$path = $names->{entry} . $path if($names->{entry});

	if($path =~ m/^([^\/]+)\/(.+)$/) {
		$root = $1;
		$leaf = $2;
	}
	else {
		$root = $path;
		$leaf = undef;
	}
	if($leaf) {
		if($url =~ m/#2/) {
			$url =~ s/#1/$root/g;
			$url =~ s/#2[!]?/$leaf/g;
		}
		else {
			$url =~ s/#1/$path/g;
		}
		$url =~ s/#shortname#/$leaf/g;
	}
	else {
		$url =~ s/#1/$root/g;
		$url =~ s/#2!/$root/g;
		$url =~ s/[\/\.\-]?#2//g;
		$url =~ s/#shortname#/$path/g;
	}
    #$url =~ s/\/+$//;
	#$url =~ s/\.{2,}([^\/]+)/\.$1/g;
	if($url and $id) {
		$url =~ s/:\/\//:\/\/$id\@/;
	}
	#print STDERR "\t To $url\n";	
    return $url;
}

sub parse_url {
	my $self = shift;
	my $name = shift;
	my $template = shift;
	my $project = shift;
	return unless($template);
	#if($template =~ m/\/$/) {
	#	$template = $template ."$name"; 
	#}
	if($template =~ m/^(.+)\/#([^#]+)#$/) {
		if($project->{$2}) {
			$template = "$1/$project->{$2}";
		}
	}
	my $user = $project->{login};
	if($template =~ m/^([^\/\@]+)\@(.+)$/) {
		$template = $2;
		$user = $1;
	}
	my $host;
	my $service;
	my %names = (
		'name'=>$name || $project->{name},
		'group'=>$project->{group},
	);
	if($template =~ m/^\s*([^\.\/]+)\.([^\/]+)\/(.*?)\s*$/) {
		$host = $self->{hosts}->{$1};
		$service = $2;
		$names{fullname} = $3;
	}
	elsif($template =~ m/^\s*([^\/]+)\/(.*?)\s*$/) {
		$host = $self->{hosts}->{$1};
		$names{fullname} = $2;
	}
	if($template =~ m/\/$/) {
		my $default_entry = '';
		if($project->{default_entry}) {
			$default_entry = $project->{default_entry};
		}
		elsif(ref $host) {
			if($host->{map} and $host->{map} eq 'localname') {
				$names{name} = $project->{localname} if($project->{localname});
			}
			for($host->{name},$host->{$service}->{default}){
				if($_ && $project->{$_}) {
					$default_entry = $project->{$_};
					last;
				}
			}
		}
		$names{fullname} = $default_entry;
	}
	my ($push,$pull,$type);
	if($host) {
		if(ref $host->{$service} and $host->{$service}->{write}) {
			$push = translate_url($host->{$service}->{write},\%names,$user);
		}
		elsif($host->{write}) {
			$push = translate_url($host->{write},\%names,$user);
		}
		elsif($host->{$service}) {
			$push = translate_url($host->{$service},\%names,$user);
		}

		if(ref $host->{$service} and $host->{$service}->{read}) {
			$pull = translate_url($host->{$service}->{read},\%names,$user);
		}
		elsif($host->{read}) {
			$pull = translate_url($host->{read},\%names,$user);
		}
		elsif($push) {
			$pull = $push;
		}

		$push = $pull if(!$push);
		$type = $host->{$service}->{type} if(ref $host->{$service});
		$type = $service || $host->{type} unless($type); 
	}

	if(!$push) {
		$push = $pull =  translate_url($template,\%names,$user);
	}
	if(!$type) {
		$type = $project->{type};
	}
	if((!$type) and $pull =~ m/[\/\.](git|svn|hg)$/) {
		$type = $1;
	}
	return {'push'=>$push,'pull'=>$pull,'user'=>$user,'type'=>$type};
}

sub new_repo {
    #my ($query_name,@repo_data) = @_;
	my $self = shift;
	my $name = shift;
	my $project = shift;
	my %r;
	$project = {'source'=>'local.git/'} unless($project);
	%r = %{$project};
#	foreach(qw/shortname name localname email author type checkout login/) {
#		$r{$_} = $project->{$_} || $self->{config}->{$_};
#		delete $r{$_} unless($r{$_});
#	}
    $r{shortname} = $name if($name);
	$r{name} = $r{shortname} unless($r{name});
	$r{localname} = $r{name} unless($r{localname});
	foreach(keys %{$self->{maps}->{localname}}) {
		$r{localname} =~ s/$_/$self->{maps}->{localname}->{$_}/g;
	}
	$r{login} = $r{login} 
				|| $project->{user} 
				|| $project->{username};
	$r{target} = $r{checkout} || $name;
	if($r{target} =~ m/\/$/) {
		$r{target} .= $name;
	}
	foreach my $key (qw/source origin mirror/) {
		if($project->{$key}) {
			my $url = $self->parse_url($r{name},$project->{$key},\%r);
			push @{$r{$url->{type}}},$url if($url);
		}
	}
	foreach (keys %{$project}) {
		if(m/^mirror_.+/) {
			my $url = $self->parse_url($r{name},$project->{$_},\%r);
			push @{$r{$url->{type}}},$url if($url);
		}
	}
	if($project->{"mirrors"}) {
		foreach(@{$project->{"mirrors"}}) {
			next unless($_);
			my $url = $self->parse_url($r{name},$_,\%r);
			push @{$r{$url->{type}}},$url if($url);
		}
	}
    return \%r;
}
1;

__END__
=pod

=head1  NAME

MyPlace::Reposman::Projects - PERL Module

=head1  SYNOPSIS

use MyPlace::Reposman::Projects;

=head1  DESCRIPTION

___DESC___

=head1  CHANGELOG

    2011-12-05 22:00  xiaoranzzz  <xiaoranzzz@myplace.hell>
        
        * file created.

		* copy codes form reposman.pl

=head1  AUTHOR

xiaoranzzz <xiaoranzzz@myplace.hell>


# vim:filetype=perl

