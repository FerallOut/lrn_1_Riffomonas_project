#!/usr/bin/env bash

## download these files to the "data/" directory
## "-nc" only redownload next time if there is a newer file version than what is downloaded
wget -nc -P data/ https://www.ncei.noaa.gov/pub/data/ghcn/daily/ghcnd-inventory.txt