#!/usr/bin/env bash

echo $1

sed -i 's/💎:/sort:/g' $1
sed -i 's/🚀:/spin:/g' $1
sed -i 's/🔨:/span:/g' $1
sed -i 's/📂:/suit:/g' $1

PATH=${1##*/} && SORT=${PATH%.*}
[[ "$SORT" == "2" ]] && sed -i "1s|^|---\nsort: $SORT\n---\n|" $1

#---
#💎: 5
#🚀: 18
#🔨: 163
#📂: 2
#---

IFS=$'\n' read -d '' -r -a array < _Sidebar.md
echo ${array[2]};
