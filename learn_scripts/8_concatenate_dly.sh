#!/usr/bin/env bash

## instead of openinig a whole .tar.gz archive
## -O - decompress to stdout 
## filter the output to decrease the size of the files
## gzip the files (not a tar archive!)

#tar -Oxvzf data/practice.tar.gz | \
#    grep "PRCR" | \
#    gzip > data/ghcnd_concat.out.gz   ## remove this output from Snakefile bc the rule changes below
#------------------

## split into files of 1.000.000 lines each - changed to 500.000 later to decrease RAM
## and output them to the "temp" dir

mkdir -p data/temp
tar -Oxvzf data/ghcnd_all.tar.gz | \
    grep "PRCP" | \
    split -l 500000 --filter 'gzip > data/temp/$FILE.gz'


## call script 9_read_split_dly_files_all.R 
## to run the modifications on each split file
scripts/9_read_split_dly_files_all.R

## clean up data
rm -rf data/temp 
