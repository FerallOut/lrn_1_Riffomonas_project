#!/usr/bin/env bash

## 1. using the "get_ghcnd_data.sh", download various files

# get the daily data from the weather stations
scripts/4_get_ghcnd_data.sh ghcnd_all.tar.gz

# get listing of types of data found at each weather station
scripts/4_get_ghcnd_data.sh ghcnd-inventory.txt

# get metadata for each weather stations
scripts/4_get_ghcnd_data.sh ghcnd-stations.txt



## 2. "get_ghcnd_all_files.sh" lists all the files in the "ghcnd_all.tar.gz" archive
# generate list of stations
scripts/6_get_ghcnd_all_files.sh