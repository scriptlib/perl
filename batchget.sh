#!/bin/sh

puf=`which puf`

if [ -n "$puf" ] ; then
    exec batchget-puf "$@"
else
    exec batchget-nopuf "$@"
fi
