#!/bin/bash

if ! zstd --version &>/dev/null; then
  >&2 echo please install zstd
  exit 1
fi

force=false
if [ $# -gt 0 ] && [ "$1" == "-f" ] || [ "$1" == "-B" ]; then
  force=true
fi

t=false  # if both stdin & stdout are an interactive terminal
if [ -t 0 ] && [ -t 1 ]; then t=true; fi
rgbprintf() {
  local r=$1; shift
  local g=$1; shift
  local b=$1; shift
  local c=$[ 16 + 36*(r % 6) + 6*(g % 6) + (b % 6) ]
  local fmt="$1"; shift
  $t && fmt="\e[38;5;${c}m$fmt\e[m"
  printf "$fmt" "$@"
}

compress() {
  if $force || [ "$1" -nt "$1.zst" ]; then
    rgbprintf 5 3 2 "↕ Compressing %s... " "$1"
    < "$1" tr -d $' \n' | zstd -19 > "$1.zst"
    rgbprintf 2 5 2 "%s\n" "done ✓"
  fi
}

################################################################################
# big files

compress words.json

compress ayat.json

compress lineends.json

compress suarayat.json

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

rgbprintf 1 5 5 "→ Writing allmeta.json... "

{
  printf '{ "%s":%d\n, "%s":%d\n' width 776 height 1053
  for j in $allmeta; do
    printf ', "%s":\n%s\n' "$j" "$(sed 's/^/  /' $j.json)"
  done
  printf '}'
} > allmeta.json

rgbprintf 2 5 2 "%s\n" "done ✓"

compress allmeta.json

# I use prefix commas because they are less error-prone in JSON.
