#!/usr/bin/perl -w
package NightGun::Store::WebSaver;
use warnings;
use base qw/NightGun::Store/;
use strict;
my $path_sep = "::WebSaver::";
my $location_exp = qr/^(.*)$path_sep(.*)$/;

sub new {
	return NightGun::Store::new(@_);
}

sub load {
	my($self,$path)=@_;
	my ($source,$entry,@data);
	if($path =~ $location_exp) {
		$source = $1;
		$entry = $2;
	}
	else {
		$source = $path;
	}
        return unless($source =~ m/\.xml$/i);
	if(-f $source) {
		open FI,"<:",$source or return undef;
		@data=<FI>;
		close FI;
	}
	else {
		return undef;
	}
        use XML::Simple;
        my $xml = XMLin(join("",@data));
        return undef unless($xml->{Item});
        use Data::Dumper;print STDERR (Dumper($xml));
        use Encode;
        my $utf8 = Encode::find_encoding("UTF-8");
        
        $self->{files}=undef;
        $self->{dirs}=undef;
        $self->{root}=$source;
        $self->{id}=$path;
        $self->{data}=undef;
        $self->{parent}=$source;
	$self->{parent} =~ s/\/[^\/]+$/\//;
        $self->{leaf}=undef;
        $self->{donot_encode}=1;
        #$self->{donot_escape}=1;
        if($entry) {
            my $found = undef;
            $self->{leaf} = $source . $path_sep . $entry;
            $self->{title} = $entry;
            my $enc_entry = $utf8->decode($entry);
            print STDERR "looking for $entry:\n";
            my $index = 0;
            foreach my $item (@{$xml->{Item}}) {
                print STDERR '???'. $item->{label} . '?' . "\n";
                $index++;
                if("$index." . $item->{label} eq $enc_entry) {
                    $found = 1;
                    print STDERR "$entry found!\n";
                    my $type = $item->{type};
                    if($type eq "image") {
                        $self->{type}=NightGun::Store->TYPE_URI;
                        $self->{data}=$item->{data};
                    }
                    else {
                        $self->{type}=NightGun::Store->TYPE_STREAM;
                        $self->{data}=$utf8->encode($item->{content});
                    }
                }
            }
            if(not $found) {
                        $self->{type}=NightGun::Store->TYPE_STREAM;
                        $self->{data}="Entry not found";
            }
        }
        else {
            my $enc_source = $utf8->decode($source);
            my $index=0;
            foreach my $item (@{$xml->{Item}}) {
                $index++;
                push @{$self->{files}},$enc_source . $path_sep . "$index." . $item->{label};
            }
	    $self->{title}=$source;
	    $self->{title} =~ s/^.*\///;
        }
	return $self;
}

sub parse_location {
	my($self,$path)=@_;
	return undef unless($path =~ $location_exp);
	return ($1,$path);
}
