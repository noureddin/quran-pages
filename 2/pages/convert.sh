#!/bin/bash

if ! convert --version &>/dev/null; then
  >&2 echo please install imagemagick
  exit 1
fi

if ! exiftool -ver &>/dev/null; then
  >&2 echo please install libimage-exiftool-perl
  exit 1
fi

if ! [ -e 776x1053/ ]; then
  >&2 echo 'directory 776x1053/ not found; please run `bash getpages.sh` first'
  exit 1
fi

md() { mkdir -p "$1" && cd "$1"; }

___jpg() {  # remove metadata and compress slightly (images become about 90% in size)
  (md "$3"
  [ -s "$1.jpg" ] || rm -f "$1.jpg"  # if empty
  [ -e "$1.jpg" ] || {
    if   [ "$1" = "605" ]; then ___jpg "empty-odd"  "$2" "."; return
    elif [ "$1" = "606" ]; then ___jpg "empty-even" "$2" "."; return
    fi
    # remove metadata, except the color profile (which is only 4KB, but might cause color issues?)
    # then compress the first two page twice (only twice to not alter the color quality noticeably)
    # but the rest don't compress better, thus kept. then provide a numeric name for the empty pages.
    exiftool -q -all= --ICC_Profile:all "$2$1.jpg" -o "$1...jpg" && {
      case "$1" in
      1|2)
        convert "$1...jpg" "$1..jpg" &&
        convert "$1..jpg" "$1.jpg" ;;
      empty-odd)
        mv "$1...jpg" "$1.jpg" &&
        { ln "$1.jpg" "605.jpg" || cp -f "$1.jpg" "605.jpg"; } ;;
      empty-even)
        mv "$1...jpg" "$1.jpg" &&
        { ln "$1.jpg" "606.jpg" || cp -f "$1.jpg" "606.jpg"; } ;;
      *)
        mv "$1...jpg" "$1.jpg" ;;
      esac
    }; } &&
    rm -f "$1...jpg" "$1..jpg" ||
      goterror "$1.jpg"
  echo -n "$1"/;)  # auto `cd -` because of the subshell
}

___webp() {  # remove metadata and compress to webp (images become about 50% in size)
  (md "$3"
  [ -s "$1.webp" ] || rm -f "$1.webp"  # if empty
  [ -e "$1.webp" ] || {
    if   [ "$1" = "605" ]; then ___webp "empty-odd"  "$2" "."; return
    elif [ "$1" = "606" ]; then ___webp "empty-even" "$2" "."; return
    fi
    # remove metadata, except the color profile (which is only 4KB, but might cause color issues?)
    # then compress to webp twice (once is not enough to reduce its size)
    exiftool -q -all= --ICC_Profile:all "$2$1.jpg" -o "$1.jpg" &&
    convert "$1.jpg" "$1.WEBP" &&
    convert "$1.WEBP" "$1.webp" && {
      case "$1" in
      empty-odd)
        ln "$1.webp" "605.webp" || cp -f "$1.webp" "605.webp" ;;
      empty-even)
        ln "$1.webp" "606.webp" || cp -f "$1.webp" "606.webp" ;;
      esac
    }; } &&
    rm -f "$1.jpg" "$1.WEBP" ||
      goterror "$1.webp"
  echo -n "$1"/;)  # auto `cd -` because of the subshell
}
 
___avif() {  # remove metadata and compress to avif (images become about 37% in size)
  (md "$3"
  [ -s "$1.avif" ] || rm -f "$1.avif"  # if empty
  [ -e "$1.avif" ] || {
    if   [ "$1" = "605" ]; then ___avif "empty-odd"  "$2" "."; return
    elif [ "$1" = "606" ]; then ___avif "empty-even" "$2" "."; return
    fi
    # remove metadata, except the color profile (which is only 4KB, but might cause color issues?)
    # then compress to avif thrice
    exiftool -q -all= --ICC_Profile:all "$2$1.jpg" -o "$1.jpg" &&
    convert "$1.jpg" "$1...avif" &&
    convert "$1...avif" "$1..avif" &&
    convert "$1..avif" "$1.avif" && {
      case "$1" in
      empty-odd)
        ln "$1.avif" "605.avif" || cp -f "$1.avif" "605.avif" ;;
      empty-even)
        ln "$1.avif" "606.avif" || cp -f "$1.avif" "606.avif" ;;
      esac
    }; } &&
    rm -f "$1.jpg" "$1...avif" "$1..avif" ||
      goterror "$1.avif"
  echo -n "$1"/;)  # auto `cd -` because of the subshell
}

_light_jpg() { ___jpg "$1" "../776x1053/" "776x1053-jpg"; }

_light_webp() { ___webp "$1" "../776x1053/" "776x1053-webp"; }

_light_avif() { ___avif "$1" "../776x1053/" "776x1053-avif"; }

loop() {
  haserror && return
  # $1 is the exec/func to call
  # $2 is the number of concurrent processes
  # the rest are passed to function after the page number
  printf "\n%s\n" $1
  for i in {1..606}; do  # pages 605 and 606 are empty-odd & empty-even, repsectively
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

# this requires calling "_get" in "getpages.sh" first;
# uncomment the line starting with "loop _get" there and run that script.

# then uncomment any of the following

# loop _light_jpg $N

# loop _light_webp $N

# loop _light_avif $N

set +x
rm -f "$t"  # don't comment or remove this line!

