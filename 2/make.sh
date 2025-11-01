#!/bin/bash

if ! zstd --version &>/dev/null; then
  >&2 echo please install zstd
  exit 1
fi

force=false
if [ $# -gt 0 ] && [ "$1" == "-f" ] || [ "$1" == "-B" ]; then
  force=true
fi

compress() {
  if $force || [ "$1" -nt "$1.zst" ]; then
    printf "Compressing %s... " "$1"
    < "$1" tr -d $' \n' | zstd -19 > "$1.zst"
    printf "done\n"
  fi
}

################################################################################
# big files

compress words.json

compress lines.json

compress ayat.json

compress lastwords.json

compress pauses.json

compress morepauses.json

################################################################################
# allmeta.json

allmeta="colors margins marginwords numberofwords numberofayat suarstarts headers basmalaat lessersplits"
needed=$force
if ! $force; then
  for j in $allmeta; do
    if [ $j.json -nt allmeta.json ]; then needed=true; break; fi
  done
fi

if ! $needed; then exit; fi

printf "Making allmeta.json... "

{
  printf '{ "%s":%d\n, "%s":%d\n' width 776 height 1053
  for j in $allmeta; do
    printf ', "%s":\n%s\n' "$j" "$(sed 's/^/  /' $j.json)"
  done
  printf '}'
} > allmeta.json

compress allmeta.json

# I use prefix commas because they are less error-prone in JSON.
