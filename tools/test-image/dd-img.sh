#!/bin/bash 

if [ "$1" == "" ] ; then
    echo "$0 -in_filename (w/o .nex )"
    exit -1
fi

in_name=$1

in_file=$in_name.nes
out_file1=$in_name-prg.bin
out_file2=$in_name-chr.bin

echo in_file=$in_name.nes
echo out_file1=$in_name-prg.bin
echo out_file2=$in_name-chr.bin

echo "processing...."

dd if=$in_file of=$out_file1 bs=16 skip=1 count=2048 2> /dev/null
dd if=$in_file of=$out_file2 bs=16 skip=2049 2> /dev/null
#4k img creation
#dd if=sample1-prg.bin of=sample1-prg-4k.bin bs=512 count=8

echo "done."
