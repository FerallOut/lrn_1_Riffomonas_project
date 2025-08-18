#!/usr/bin/env bash

## since for the previous 3 scripts 
## the only difference was the name of the script to download
## but the path was always the same,
## we can use the same script to download all the files

file=$1
## download these files to the "data/" directory
## "-nc" only redownload next time if there is a newer file version than what is downloaded
wget -nc -P data/  https://www.ncei.noaa.gov/pub/data/ghcn/daily/$file