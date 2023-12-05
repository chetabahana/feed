#!/usr/bin/env bash

echo $1

sed -i 's/💎:/sort:/g' $1
sed -i 's/🚀:/spin:/g' $1
sed -i 's/🔨:/span:/g' $1
sed -i 's/📂:/suit:/g' $1

PATH=${1##*/} && NUM=${PATH%.*}
[[ "$NUM" == "2" ]] && echo match
#sed -i "1s|^|---\nsort: $n\n---\n|" $1

IFS=$'\n' read -d '' -r -a array < _Sidebar.md
echo ${array[2]};
