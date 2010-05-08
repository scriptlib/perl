#!/bin/bash

fname=$1
nname=$2

if [ -z "$fname" ] ; then
    echo "Filename required."
    exit 1
fi
if [ -z "$nname" ] ; then
    echo "New Filename required."
    exit 1
fi

PLDIR=$XR_PERL_SOURCE_DIR
[ -d "$PLDIR" ] || echo "\$XR_PERL_SOURCE_DIR not set or not valid" >&2 

fsrc=$PLDIR/$fname.pl
nsrc=$PLDIR/$nname.pl

SHDIR=$XR_PERL_BINARY_DIR;
[ -d "$SHDIR" ] || echo "\$XR_PERL_BINARY_DIR not set or not valid" >&2
flnk=$SHDIR/$fname
nlnk=$SHDIR/$nname

if [ -f "$fsrc" ] ; then
    mv -v "$fsrc" "$nsrc"
    sed -i -e "s/$fname/$nname/g" "$nsrc"
else
    echo "$fsrc not exists."
fi

if [ -h "$flnk" ] ; then
    mv -v "$flnk" "$nlnk"
fi
ln -vfs "$nsrc" "$nlnk" 
