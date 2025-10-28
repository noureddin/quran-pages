#!/bin/bash

if ! convert --version &>/dev/null; then
  >&2 echo please install imagemagick
  exit 1
fi

if ! exiftool -ver &>/dev/null; then
  >&2 echo please install libimage-exiftool-perl
  exit 1
fi

md() { mkdir -p "pages/$1" && cd "pages/$1"; }

_webp() {  # remove metadata and compress to webp (images become about 50% in size)
  (md 776x1053-webp
  [ -s "$1.webp" ] || rm -f "$1.webp"  # if empty
  [ -e "$1.webp" ] || {
    exiftool -q -all= --ICC_Profile:all "../776x1053/$1.jpg" -o "$1.jpg" &&  # remove metadata, except the color profile (which is only 4KB, but might cause color issues?)
    convert "$1.jpg" "$1.WEBP" &&
    convert "$1.WEBP" "$1.webp"; } &&
    rm -f "$1.jpg" "$1.WEBP" ||
      goterror "$1.webp"
  echo -n "$1"/;)  # auto `cd -` because of the subshell
}

loop() {
  haserror && return
  # $1 is the exec/func to call
  # $2 is the number of concurrent processes
  # the rest are passed to function after the page number
  printf "\n%s\n" $1
  for i in {1..604}; do
    $1 $i "${@:3}" &
    [ $((i % $2)) -eq 0 ] && wait &>/dev/null
    haserror && break
  done
  wait &>/dev/null
  echo
}

N=$(cat /proc/cpuinfo | grep processor | wc -l)  # number of processors/cores

t="$(mktemp)"
haserror() { grep -q E "$t"; }
goterror() { echo -n E >> "$t"; [ -n "$1" ] && rm -rf "$1"; }

# set -x

loop _webp $N

set +x
rm -f "$t"  # don't comment this!

