#!/bin/bash

# define DEBUG, colors & echo-color
# colors
red='\e[0;31m'
lred='\e[1;31m'
green='\e[0;32m'
lgreen='\e[1;32m'
gray='\e[1;30m'
blue='\e[0;34m'
lblue='\e[1;34m'
yellow='\e[1;33m'
NC='\e[0m' # No Color

echo "Usage:"
echo "$0 [File=russian_nouns.txt] [length=5]"
echo
echo 'result was stored in the file "${length}-${file}"'
echo

file=${1:-russian_nouns.txt}
length=${2:-5}



awk 'length($0)=='${length} ${file}  > ${length}-${file} &&  echo -e  "${green}OK${NC}"|| echo -e "${red}ERROR${NC}"