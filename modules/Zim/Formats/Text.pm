package Zim::Formats::Text;

use strict;
no warnings;
use Zim::Formats;

our $VERSION = '0.24';
our @ISA = qw/Zim::Formats/;

# TODO: some tags can be nested: email links for example

=head1 NAME

Zim::Formats::Wiki - Wiki text parser

=head1 DESCRIPTION

This is the default parser for Zim.
It uses a wiki-style syntax to format plain text.

FIXME more verbose description

All format types are signified by double characters,
this is done to prevent accidental formatting when the same
characters are used normally in a text. For the same reason
the strike character is '~' instead of '-' because '--' can
occur in normal ascii text. In the regexes we try to always
match the inner pair if more than two of these characters
are encountered. (Thus if we see C<***bold***> we should match
C<*(**bold**)*>.)


=head1 METHODS

=over 4

=item C<load_tree(IO, PAGE)>

Reads plain text from a filehandle and returns a parse tree.

=cut

sub load_tree {
warn "-> Zim::Format::Text load_tree()\n";
	my ($class, $io, $page) = @_;

	my @tree;
        my $first_line;
        while (<$io>) {
            $first_line = $_;
            next unless($first_line =~ /\S/);
            last;
        }
        if($first_line) {
            chomp($first_line);
            push @tree,['head1',{},$first_line];
        }
        while(<$io>) {
	    push @tree,['verbatim', {},$_];
        }
	return ['Page', {}, @tree];
}

our @parser_subs = qw/
	parse_verbatim
	parse_links
	parse_images
	parse_styles
	parse_urls
/;

sub save_tree {
warn "-> Zim::Format::Text save_tree()\n";
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

__END__

=back

=head1 AUTHOR

Jaap Karssenberg (Pardus) E<lt>pardus@cpan.orgE<gt>

Copyright (c) 2005 Jaap G Karssenberg. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Zim>,
L<Zim::Page>

=cut

