# Quran Pages

Images of pages are from: <https://www.islamicbook.ws/>. Directory names follow IslamicBook names.

IslamicBook has the images as JPG. This repository contains them in a compressed WebP format (most pages become about 50% in size).
Feel free to you either. (But note if you use the IslamicBook's images, the images of pages 1 & 2 have slightly different dimensions. The images in this repository are uniformly 776×1053.)

Currently only [tajweed-colored Muṣħaf Dar-ul-Ma‘refa](https://www.islamicbook.ws/2/) is supported in this project.
Because it's the only printed muṣħaf where the words don't overlap,
thus a simple rectangle is almost always enough to perfectly contain a word.

## Included images and related scripts

- `2/getpages.sh`: a Bash script using ImageMagick and Wget to download the page images from IslamicBook, fix the dimensions of the first pages, and possibly make other versions of the page images (cropped and scaled down, or double (facing) pages).

- `2/convert.sh`: a Bash script using ImageMagick and `exiftool` to compress the JPG page images to WebP half the original size.

- `2/pages/776x1053-webp/`: the compressed page images created with `2/convert.sh`. (The original JPGs are not included; use `2/getpages.sh` if you need them.)

  Note: File names are NOT zero-padded; eg, the first page is at `2/pages/776x1053-webp/1.webp`.

## Included data

- `words.json`: a JSON file whose root element is a 604-element array, each element is an array of words in a page, each is 4-tuple (array) containing the `x` (left) of the word, the `y` (top), the width, and height. All dimensions are to relative to the 776×1053 page. It's also available compressed in `words.json.zst`. (I personally use [fzstd](https://github.com/101arrowz/fzstd) on the Web.)

  The first two pages have their last "word" actually be the margin ("كلمات القرآن"). The margins of all other pages are two constant rectangles:
  the margin of the right (odd) page is `[660,0,115,1052]`, and the margin of the left (even) page is `[0,0,110,1052]`.

  The background color of words is pure white (`rgb(255, 255, 255)` = `#FFFFFF`), but the margins' background color is `rgb(255, 253, 216)` = `#FFFDD8`.

There are other data that will be added gradually.

## License

The images are copyright of their original authors at [Dar-ul-Ma‘refa](https://www.easyquran.com/). Any derivatives I present here are still their copyright.

All the code and data I present here is under Creative Commons Zero (equivalent to Public Domain).


