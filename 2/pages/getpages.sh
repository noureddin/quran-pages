#!/bin/bash

HOST='https://www.islamicbook.ws/2/'

if ! convert --version &>/dev/null; then
  >&2 echo please install imagemagick
  exit 1
fi

if ! wget --version &>/dev/null; then
  >&2 echo please install wget
  exit 1
fi

md() { mkdir -p "$1" && cd "$1"; }

_get() {  # download mosħaf pages
  (md 776x1053
  opt=""
  [ $1 -eq 1 ] && opt='-crop 776x1053+25+25'
  [ $1 -eq 2 ] && opt='-crop 776x1053+36+25'
  [ -s "$1.jpg" ] || rm -f "$1.jpg"  # if empty
  [ -e "$1.jpg" ] || {
    if wget -U Mozilla/5.0 -q "$HOST/$1.jpg"; then
      if [ $1 -eq 1 ] || [ $1 -eq 2 ]; then
        mv $1.jpg _$1.jpg &&
        convert _$1.jpg $opt $1.jpg &&
        rm -f _$1.jpg ||
          goterror "$1.jpg"
      fi
    else
      goterror "$1.jpg"
    fi

  }
  echo -n "$1"/;)  # auto `cd -` because of the subshell
}


_bw() {  # make black&white (1-bit) images for edge detection
  (md 776x1053-bw
  [ -s "$1.pbm" ] || rm -f "$1.pbm"  # if empty
  [ -e "$1.pbm" ] ||
    convert "../776x1053/$1.jpg" -threshold 50000 "$1.pbm" ||
      goterror "$1.pbm"
  echo -n "$1"/;)  # auto `cd -` because of the subshell
}

### chop to fit 640x960 (vert.) then resize to fit 320x480 (vert.)
### 640x960 is exactly twice 320x480.

_CONVERT_COMPRESS_ARGS=' -sampling-factor 4:2:0 -strip -quality 85 -colorspace RGB -interlace JPEG '

__mini() {
  (md $2
  dark=''
  if [[ $2 = *-dark ]]; then dark='-dark'; fi
  if [ $1 -eq 1 ]; then
    local args=" -shave 58x34 -chop 20x25+640+0 "
  elif [ $1 -eq 2 ]; then
    local args=" -shave 52x34 -chop 32x25+0+0 "
  else
    [ $(( $1 % 2 )) -eq 0 ] && g='110x65+0+960' || g='110x65+666+960'  # cropping the margin
    local args=" -chop $g -shave 13x0 -chop 0x20 -gravity South -chop 0x8 "
  fi
  [ -s "$1.jpg" ] || rm -f "$1.jpg"  # if empty
  [ -e "$1.jpg" ] ||
    convert "../776x1053$dark/$1.jpg" $args $_CONVERT_COMPRESS_ARGS ${@:3} "$1.jpg" ||
        goterror "$1.jpg"
  echo -n "$1"/;)  # auto `cd -` because of the subshell
}

_640() { __mini $1 640x960$2; }
_320() { __mini $1 320x480$2 -resize 320x480; }
_240() { __mini $1 240x360$2 -resize 240x360 -unsharp 0x0.8; }

__double() {  # no dark support yet
  (md 776x1053-double
  [ $(( $1 % 2 )) -eq 0 ] && return  # ignore evens; provide only odds
  [ -s "$1.jpg" ] || rm -f "$1.jpg"  # if empty
  [ -e "$1.jpg" ] ||
    montage "../776x1053/$(($1+1)).jpg" "../776x1053/$1.jpg" \
      -tile 2x1 -geometry +0+0 ${@:3} "$1.jpg" ||
        goterror "$1.jpg"
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

# uncomment any of the following

loop _get  4  # download the original JPG images (and fix the dimensions of the first two pages)

# loop _bw  $N  # covert the downloaded JPG images into 1-bit black-and-white (not grayscale) images

# loop _640 $N  # scale the downloaded JPG images to 640x960 (and remove the margin ("كلمات القرآن"))

# loop _320 $N  # one half the dimensions of 640x960

# loop _240 $N  # one third the dimensions of 640x960 (almost illegible)

# loop __double $N   # make a single image of every two facing pages (full size (776x1053) only)

# TODO: dark

set +x
rm -f "$t"  # don't comment this!

