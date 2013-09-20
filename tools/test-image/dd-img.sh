#!/bin/bash 

if [ "$1" == "" ] ; then
    echo "$0 -in_filename (w/o .nex )"
    exit -1
fi

in_name=$1

in_file=$in_name.nes
out_file1=$in_name-prg.bin
out_file2=$in_name-chr.bin

dd if=$in_file of=$out_file1 bs=16 skip=1 count=2048
dd if=$in_file of=$out_file2 bs=16 skip=2049

