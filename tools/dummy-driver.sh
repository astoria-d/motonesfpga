#!/bin/bash

if [ -n "$1" ] ; then
    if [ "$1" = "-h" ] ; then
        echo "$0 rgb (12 bit hex format)"
        exit 1;
    fi
    col=$1
else
    col=039
fi

while [ true ]
do
    for y in {0..480}
    do
        for x in {0..600}
        do
#            echo $x
            echo $col > vga-port
        done
        echo "-" > vga-port
    done;
    echo "_" > vga-port
done

