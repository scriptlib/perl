#!/bin/bash
FMODE=775
DMODE=775
for i in "$@" ; do
    if [ -f "$i" ] ; then
        chmod "$FMODE" "$i"
    elif [ -d "$i" ] ; then
        chmod "$DMODE" "$i"
    fi
done
