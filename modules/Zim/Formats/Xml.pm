package Zim::Formats::Xml;

use strict;
no warnings;
use Zim::Formats;
use XML::Simple;

our $VERSION = '0.24';
our @ISA = qw/Zim::Formats/;

sub parse_node;

sub parse_node {
    my ($indent,$node,$name) = @_;
    my @tree;
    my $type = ref $node;
    if(!$type) {
        push @tree, " "x$indent . "\x{2022} " . ((!$name or ($name eq 'content')) ? "" : "$name:") . "$node\n";
    }
    elsif($type eq "HASH") {
        push @tree,"\n";
        push @tree,&parse_node($indent,"",$name) if($name);
        foreach(keys %{$node}) {
            push @tree,&parse_node($indent+1,$node->{$_},$_);
        }
        push @tree,"\n";
    }
    else {
        push @tree,"\n";
        push @tree,&parse_node($indent,"",$name) if($name);
        foreach(@{$node}) {
            push @tree,&parse_node($indent+1,$_);
        }
        push @tree,"\n";
    }
    return @tree;
}

sub load_tree {
	my ($class, $io, $page) = @_;
	my @tree;
        my $xml = XMLin($io,KeepRoot=>1);
        my @tree = parse_node(0,$xml,"");
	return ['Page', {}, ['head1',{},$page->{name}],@tree];
}

sub save_tree {
	# TODO add support for recursive tags
	my ($class, $io, $tree) = @_;

	my $old_fh = select $io;
	eval { $class->_save_tree($tree) };
	select $old_fh;
	die $@ if $@;
}

sub _save_tree {
	my ($class, $tree) = @_;
	
	my ($name, $opt) = splice @$tree, 0, 2;
	die "Invalid parse tree"
		unless length $name and ref($opt) eq 'HASH';
                
        if(@$tree) {foreach my $node(@$tree) {
		unless (ref $node) {
			$node =~ s/^(\s*)\x{2022}(\s+)/$1*$2/mg;
			print $node;
			next;
		}
                my ($tag,$meta,$text) = @$node[0,1,2];
                #use Data::Dumper;print STDERR Data::Dumper->Dump([$tag,$meta],[qw/tag meta/]);;
                if($tag =~ /^head(\d)$/){
                    print $text,"\n",$meta->{empty_lines} ? "\n"x($meta->{empty_lines}) : "";
                }
                elsif( $tag eq 'verbatim') {
                    print $text;
                }
            
        }}

}


1;

