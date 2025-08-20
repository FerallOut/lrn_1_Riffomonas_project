#!/usr/bin/env bash

## open a .tar.gz archive and list all the files in it
## don't show the dir name, just ".dly" files
## saving output to a file
## give column a name

echo "list all files"
echo "file_name" > data/6_ghcnd_all_files.txt
tar -tf data/ghcnd_all.tar.gz | grep ".dly" >> data/6_ghcnd_all_files.txt
echo "all files listed"
