#!/usr/bin/env bash

s=${1##*/} && echo "${s%.*}"
sed -i 's/💎:/sort:/g' $1
sed -i 's/🚀:/spin:/g' $1
sed -i 's/🔨:/span:/g' $1
sed -i 's/📂:/suit:/g' $1

IFS=$'\n' read -d '' -r -a array < _Sidebar.md
echo ${array[2]};
