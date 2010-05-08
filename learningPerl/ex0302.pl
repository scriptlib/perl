#!/usr/bin/perl -W

@data=qw/fred betty barney dino Wilma pebbles bamm-bamm/;
$count=@data;

while($index=<STDIN>) {
    chomp($index);
    print("$index");
    if ($index >0 && $index <= $count) {
        print(" -> $data[$index-1]\n");
    }
    else {
        print(" -> undef\n");
    }
}
