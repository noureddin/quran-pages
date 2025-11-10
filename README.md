# Quran Pages

Images of pages are from: <https://www.islamicbook.ws/>. Directory names follow IslamicBook names.

IslamicBook has the images as JPG. This repository contains them in a compressed WebP format (most pages become about 50% in size).
Feel free to you either. (But note if you use the IslamicBook's images, the images of pages 1 & 2 have slightly different dimensions;
for these two use the JPEG images from this repo's instead. The images in this repository are uniformly 776×1053.)

Currently only the [tajweed-colored Dar-ul-Ma‘refa Muṣħaf](https://www.islamicbook.ws/2/) is supported in this project.
Because it's the only printed muṣħaf where the words don't overlap,
thus a simple rectangle is almost always enough to perfectly contain a word.

## Included images and related scripts

- `2/pages/getpages.sh`: a Bash script using ImageMagick and Wget to download the page images from IslamicBook,
  fix the dimensions of the first pages, and possibly make other versions of the page images (cropped and scaled down, or double (facing) pages).

- `2/pages/convert.sh`: a Bash script using ImageMagick and `exiftool` to convert the JPG page images.

- `2/pages/776x1053/`: only `1.jpeg` and `2.jpeg` (notice the `e` in `jpeg`).
  These two are included because the original have different dimensions.
  The original JPGs are not included; fetch them from IslamicBook, or use `getpages.sh` if you need them.

- `2/pages/776x1053-webp/`: all the pages' images (1 throught 604) in WebP format, which is half the size of the original JPEG images.

  Note: File names are NOT zero-padded; eg, the first page is at `2/pages/776x1053-webp/1.webp`.

## Included primary data

- `2/data/words.json`: a JSON file whose root element is a 604-element array representing the pages,
  each element is an array of words in a page,
  each word is a 4-tuple (array) containing the `x` (left) of the word, the `y` (top), the width, and height.

  All dimensions are to relative to the 776×1053 page.

  It's also available compressed in `2/data/words.json.zst`.
  (I personally use [fzstd](https://github.com/101arrowz/fzstd) on the Web.)

- `2/data/lineends.json` (notice the two `e`s): a JSON file whose root element is a 604-element array representing the pages,
  each element is an array of "lines" in the page,
  each "line" is the index of the word that ends that line.

  For example, `lineends[0]` is `[0, 2, 8, ...]`, that means
  that the first line in the first page is the word `words[0][0]`,
  and the second line is the words `words[0][1]` and `words[0][2]`,
  and the third line is the words `words[0][3]` through `words[0][8]`.

  It's also available compressed in `2/data/lineends.json.zst`.

- `2/data/ayat.json`: a JSON file whose root element is a 604-element array representing the pages,
  each element is an array of ayat in a page,
  each ayah is the word index of its number-mark into the page.

  For example, the first page is `[ 2, 7, ...]`, meaning that the first ayah
  in the page ends with the third (ie, `[2]`) word. That's true; the first three
  words of the first page are: the sura name, the basmala ligature, and the
  number "1" in an end-of-ayah mark.

  It's also available compressed in `2/data/ayat.json.zst`.

- `2/data/pauses.json`: a JSON file whose root element is a 604-element array representing the pages,
  each element is an array of pauses (waqfs and/or gaps) in a page,
  each pause is the word index the word immediately preceding it.

  It's also available compressed in `2/data/pauses.json.zst`.

  Note: Split waqf (الوقف المتعانق) is recorded only for the one with the gap in the Dar-ul-Ma‘refa Muṣħaf;
  the other one is moved to `2/data/lessersplits.json` described below.

- `2/data/morepauses.json`: a (work-in-progres) JSON file in the same format as `pauses.json`.
  Please read [morepauses.description](2/morepauses.description) for info and details.

  It's also available compressed in `2/data/morepauses.json.zst`.

## Included metadata and related scripts

These all are tiny files. You can embed the files you need, or fetch the combined
`2/data/allmeta.json` descripted below (or its compressed version `2/data/allmeta.json.zst`).

- `2/data/numberofwords.json`: a JSON file whose root element is a 604-element array representing the pages,
  each element contains just the number of elements of the corresponding array in `2/data/words.json`.

- `2/data/numberofayat.json`: a JSON file whose root element is a 604-element array representing the pages,
  each element contains just the number of elements of the corresponding array in `2/data/ayat.json`.

- `2/data/margins.json`: a JSON file whose root element is an object
  that contains the margins ("كلمات القرآن") of the pages.
  It contains exactly four key-value pairs:
  the keys `1` and `2` for the margins of the first two pages,
  and `odd` and `even` for the margins of the odd/right and even/left pages, respectively.
  The values are tuples exactly like `2/data/words.json`.

- `2/data/marginwords.json`: a JSON file whose root element is an object
  whose keys are 1-based page numbers that have white-background words in the margin as hints for reciting.
  The values are an object,
  whose `idx` key has the index of the corresponding word in `2/data/words.json` in the page,
  and whose `dim` key has a dimension tuple exactly like `2/data/words.json`.

  Note: "words" have a white background and are inside the page,
  "margins" have a yellowish background and are outside the page (and there is only one margin in a given page),
  and "marginwords" sit on the fence between the two - literally;
  they have a white background and sit on the border between the "words" and the "margin".
  Also, they exists only in some pages, but only once in a page.

- `2/data/colors.json`: a JSON file containing the background colors of the words and the margins,
  in both HTML hexadecimal format and as an RGB tuple, for the (default) light pages' images,
  and for the soon-to-be-uploaded dark pages' images.

- `2/data/lessersplits.json`: a JSON file whose root element is an object
  whose keys are 1-based page numbers that have split waqf.
  The values are the split waqfs that are "unfavoured" by the Dar-ul-Ma‘refa Muṣħaf;
  the favoured ones have a gap after them and are included in primary `2/data/pauses.json` instead.

- `2/data/suarstarts.json`: a JSON file whose root element is a 114-element array representing the suar,
  mapping the suar by their number (eg., *al-Fātiħa* is the first element at index `0`, *al-Baqara* is at `1`)
  to a pair of the page/word that contains its basmala (or first word in case of sura 1 and sura 9).
  (Eg, `suarstarts[0]` is `[0,1]`, meaning that *al-Fātiħa* starts with the second "word" in the first page;
  the first "word" (at `[0,0]` is the sura name.)

- `2/data/headers.json`: a JSON file whose root element is a 604-element array representing the pages,
  each element is an array containing the word index of any header (sura name) in that page.

- `2/data/basmalaat.json` (notice the two `a`s): a JSON file whose root element is a 604-element array representing the pages,
  each element is an array containing the word index of any basmala ligature in that page.

  Note:
  Al-Fātiħa (sura 1) and at-Tawba (sura 9) have no additional basmala.
  The basmala of al-Fātiħa is its first ayah, not separate.
  Applications usually need that differentiation, for example, for reciting audio.

- `2/data/allmeta.json`: includes all other metadata JSONs (ie, not the primary data) as values in the root object;
  eg., `"marginwords"` is a key whose value is the contents of the JSON file with the same name.

  It's also available compressed in `2/data/allmeta.json.zst`.

  For convenience, `2/data/allmeta.json` also includes two additional key-value pairs:
  the dimensions of the pages in pixels: `"width": 776` and `"height": 1053`.

- `2/data/make.sh`: generates `allmeta.json`, and compresses it and the primary data JSON files.

- `2/data/generate.pl`: generates half of the metadata JSON files from the primary data and the other half.

- `2/data/jq.sh`: contains generating commands for some other probably useful formats of the same data.
  They need `jq` to be installed.

I may later add the scripts I created to help me create the words/ayat/pauses data.

## License

The images are the copyright of their original authors at Dar-ul-Ma‘refa (<https://www.easyquran.com/>). Any derivatives I present here are still their copyright.

All the code and data I present here (except images) are my own work and are distributed under the terms of Creative Commons Zero (equivalent to Public Domain).

Copyright (c) 2025 Noureddin.
