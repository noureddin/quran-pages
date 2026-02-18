# Quran Pages

These data is made for Irsaa: [noureddin.dev/irsaa](https://www.noureddin.dev/irsaa/).
([Source code](https://github.com/noureddin/irsaa/).)
But can be used in any other application.

.

The images of pages are from: <https://www.islamicbook.ws/>. Directory names follow IslamicBook names.

IslamicBook has the images as JPG. This repository contains them in a compressed WebP format (most pages become about 50% in size).
Feel free to you either. (But note if you use the IslamicBook's images, the images of pages 1 & 2 have slightly different dimensions;
for these two use the JPEG images from this repo's instead. The images in this repository are uniformly 776×1053.)

Currently only the [tajweed-colored Dar-ul-Ma‘refa Muṣħaf](https://www.islamicbook.ws/2/) is supported in this project.
Because it's the only printed muṣħaf where the words don't overlap,
thus a simple rectangle is almost always enough to perfectly contain a word.

## Included images and related scripts

- `2/pages/getpages.sh`: a Bash script using ImageMagick and Wget to download the page images from IslamicBook,
  fix the dimensions of the first two pages, and possibly make other versions of the page images (cropped and scaled down, or double (facing) pages).

- `2/pages/convert.sh`: a Bash script using ImageMagick and `exiftool` to convert the JPG page images.

- `2/pages/776x1053-jpg/`: only `1.jpg` and `2.jpg`.
  These two are included because the original have different dimensions.
  The original JPGs are not included; fetch them from IslamicBook, or use `getpages.sh` to download the originals
  (then you can run `convert.sh` with the `loop _light_jpeg $N` uncommented to compress them slightly).

- `2/pages/776x1053-webp/`: all the pages' images (1 throught 604) in WebP format, which is half the size of the original JPEG images.

  Note: File names are NOT zero-padded; eg, the first page is at `2/pages/776x1053-webp/1.webp`.

- `2/pages/776x1053-avif/`: all the pages' images in AVIF format, which is around 37% the size of the original JPEG images.

- `2/pages/776x1053-*/empty-*.*`: two empty pages: one odd and even.
Available under the names `empty-odd.jpeg` (and `.webp` and `.avif`),
and `empty-even.jpeg` (and `.webp` and `.avif`).
Also, for convenience, they are available as the fake numbered pages 605 and 606,
so `605.jpg` is the same file as `empty-odd.jpg`,
and `606.jpg` is the same file as `empty-even.jpg`.

### Fail safe!

AVIF has good support in the latest browsers, but many browsers, applications, and web sites (even GitHub!) don't support it.

WebP has a wider support, yet [Can I use](https://caniuse.com/webp) puts it at 94% global support, not significantly better than [AVIF's](https://caniuse.com/avif) 93%.

So automatically try AVIF, then WebP, then JPEG.

If you're using them in plain HTML, use the [picture element](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/picture#the_type_attribute).

If you're loading them with JavaScript, the best way I found is to rely on
[Image's onerror](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/img#image_loading_errors),
and retry with the next format.

Example:

```javascript
const QuranPagesRoot = 'https://www.noureddin.dev/quran-pages/2/'

const QuranPagesFormats = [
   { ext:'.avif', dir:QuranPagesRoot+'pages/776x1053-avif/' },
   { ext:'.webp', dir:QuranPagesRoot+'pages/776x1053-webp/' },
   { ext:'.jpg',  dir:'https://www.islamicbook.ws/2/', first:QuranPagesRoot+'pages/776x1053-jpg/' },
]
// Note: dir: ends in slash, and ext: starts with a dot

let page_fmt_idx = 0

function next_format () {
  if (page_fmt_idx >= QuranPagesFormats.length-1) { return false }
  page_fmt_idx += 1
  return true
}

function image_src (p) {
  if (isNaN(p) || !Number.isInteger(p) || p < 1 || p > 604) {
    throw `Invalid page number: expected a number between 1 and 604 inclusive; got '${p}'`
  }
  //
  const { ext, dir, first } = QuranPagesFormats[page_fmt_idx]
  //
  return p < 3 && first
    ? first + p + ext
    : dir + p + ext
}

// then:

function get_page_with_callback (p, callback) {
  if (isNaN(p) || !Number.isInteger(p) || p < 1 || p > 604) {
    throw `Invalid page number: expected a number between 1 and 604 inclusive; got '${p}'`
  }
  //
  const page = new Image()
  if (callback) { page.onload = (ev) => callback(page) }
  //
  page.onerror = () => {
    if (next_format()) { page.src = image_src(p) }
  }
  //
  page.src = image_src(p)
  return page  // the return value should not be used; rely on the callback instead
}

// and if you prefer promises or async/await:

function get_page (p) {
  return new Promise((resolve, reject) => {
    get_page_with_callback(p, (page) => resolve(page))
  })
}

// example with promises:
get_page(1).then((img) => document.body.append(img))
```


## Included primary data

- `2/data/words.json`: a JSON file whose root element is a 604-element array representing the pages,
  each element is an array of the words in a page,
  each word is a 4-tuple (array) containing the `x` (left) of the word, the `y` (top), the width, and height.

  All dimensions are to relative to the 776×1053 page.

  It's also available compressed in `2/data/words.json.zst`.

  All word rectangles are guaranteed to never overlap (except for exactly one pixel, which is okay). If a word ever overlaps with another, this is an issue I love to know about to fix it.

  **Note:** These words are considered a single word in this project:

    - Every `بعد ما` not preceded by `من` (only 3 occurrences).
    - The single word `إل ياسين` (in [37:130](https://www.noureddin.dev/recite/?preview&37/130)); it's written disconnected to accomodate other readings, but it's one word in Hafs-an-’Āṣem and you can never pause in the middle of it in this reading.
    - The disconnected preposition in `مال` (in [4:78](https://www.noureddin.dev/recite/?preview&4/78), [18:49](https://www.noureddin.dev/recite/?preview&18/49), [25:7](https://www.noureddin.dev/recite/?preview&25/7), [70:36](https://www.noureddin.dev/recite/?preview&70/36)); you can pause at it in our reading, but not start with the following word.

- `2/data/lineends.json` (notice the two `e`s): a JSON file whose root element is a 604-element array representing the pages,
  each element is an array of the "lines" in the page,
  each "line" is the index of the word that ends that line.

  For example, `lineends[0]` is `[0, 2, 8, ...]`, that means
  that the first line in the first page is the word `words[0][0]`,
  and the second line is the words `words[0][1]` and `words[0][2]`,
  and the third line is the words `words[0][3]` through `words[0][8]`.

  It's also available compressed in `2/data/lineends.json.zst`.

- `2/data/ayat.json`: a JSON file whose root element is a 604-element array representing the pages,
  each element is an array of the ayat in a page,
  each ayah is the word index of its number-mark into the page.

  For example, the first page is `[ 2, 7, ...]`, meaning that the first ayah
  in the page ends with the third (ie, `[2]`) word. That's true; the first three
  words of the first page are: the sura name, the basmala ligature, and the
  number "1" in an end-of-ayah mark.

  It's also available compressed in `2/data/ayat.json.zst`.

- `2/data/pauses.json`: a JSON file whose root element is a 604-element array representing the pages,
  each element is an array of the pauses (waqfs and/or gaps) in a page,
  each pause is the word index the word immediately preceding it.

  It's also available compressed in `2/data/pauses.json.zst`.

  Note: Split waqf (الوقف المتعانق) is recorded only for the one with the gap in the Dar-ul-Ma‘refa Muṣħaf;
  the other one is moved to `2/data/lessersplits.json` described below.

- `2/data/morepauses.json`: a (work-in-progres) JSON file in the same format as `pauses.json`.
  Please read [morepauses.description](2/morepauses.description) for info and details.

  It's also available compressed in `2/data/morepauses.json.zst`.

- `2/data/suarayat.json`: a JSON file whose root element is a 114-element array representing the suar,
  each element is a list of tuples of `p` (1-based page number) and `w` (0-based word index)
  for the first word of each ayah of the sura.

  It's also available compressed in `2/data/suarayat.json.zst`.

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
  whose `index` key has the index of the corresponding word in `2/data/words.json` in the page,
  and whose `inner` and `outer` keys have dimension tuples exactly like `2/data/words.json`,
  where `inner` is the rectangle to be erased (painted over by the margin color),
  and `outer` is the slightly bigger rectangle that includes the border,
  to be shown (copied from the original image of the page).

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

### Examples of usage

Using promises/await:

```javascript
const meta = await fetch('https://www.noureddin.dev/quran-pages/2/data/allmeta.json')
  .then((res) => res.ok ? res.arrayBuffer() : null)
  .then((buf) => JSON.parse( (new TextDecoder).decode( new Uint8Array(buf) ) ) )
```

Using callbacks:

```javascript
let meta

function start () {
  // use meta here
  console.log('main logic', meta)
}

loadMeta((obj) => { meta = obj; start() })

function loadMeta (callback) {
  fetch('https://www.noureddin.dev/quran-pages/2/data/allmeta.json')
    .then((res) => res.ok ? res.arrayBuffer() : null)
    .then((buf) => callback( JSON.parse( (new TextDecoder).decode( new Uint8Array(buf) ) ) ) )
}
```

But you really should fetch the Zstd-compressed files instead. Examples using [fzstd](https://github.com/101arrowz/fzstd):

HTML:

```html
<!-- Either --><script src="https://unpkg.com/fzstd@0.1.1"></script>
<!-- OR --><script src="https://cdn.jsdelivr.net/npm/fzstd@0.1.1/umd/index.js"></script>
<!-- OR host it on your server; it's a ~8K file. -->
```

Callback-based JS code:

```javascript
const QuranPagesData = 'https://www.noureddin.dev/quran-pages/2/data/'

function unzstd (path, callback) {
  return fetch(path)
    .then((res) => res.ok ? res.arrayBuffer() : null)
    .then((buf) => {
      callback( (new TextDecoder).decode( fzstd.decompress(new Uint8Array(buf)) ) )
    })
}

let res = {}
let resourcesLoaded

function loadResources (callback) {
  if (resourcesLoaded) { callback(); return }
  Promise.all([
      unzstd(QuranPagesData + 'words.json.zst',      (json) => { res.words        = JSON.parse(json) }),
      unzstd(QuranPagesData + 'lineends.json.zst',   (json) => { res.lineends     = JSON.parse(json) }),
      unzstd(QuranPagesData + 'suarayat.json.zst',   (json) => { res.suarayat     = JSON.parse(json) }),
      unzstd(QuranPagesData + 'ayat.json.zst',       (json) => { res.ayat         = JSON.parse(json) }),
      unzstd(QuranPagesData + 'pauses.json.zst',     (json) => { res.pauses       = JSON.parse(json) }),
      unzstd(QuranPagesData + 'morepauses.json.zst', (json) => { res.morepauses   = JSON.parse(json) }),
      unzstd(QuranPagesData + 'allmeta.json.zst',    (json) => { Object.assign(res, JSON.parse(json)) }),
  ]).then(() => {
    resourcesLoaded = true
    callback()
  })
}

// main logic

loadResources(() => {
  console.log('loaded; we have', res.words.length, 'pages')
})
```

Pure promise-based JS code:

```javascript
const QuranPagesData = 'https://www.noureddin.dev/quran-pages/2/data/'

function unzstd (path) {
  return fetch(path)
    .then((res) => res.ok ? res.arrayBuffer() : null)
    .then((buf) => (new TextDecoder).decode( fzstd.decompress(new Uint8Array(buf)) ) )
}

let res = {}
let resourcesLoaded

function loadResources () {
  if (resourcesLoaded) { return Promise.resolve() }  // return an immediately-resolvable promise
  return Promise.all([
      unzstd(QuranPagesData + 'words.json.zst')      .then((json) => { res.words        = JSON.parse(json) }),
      unzstd(QuranPagesData + 'lineends.json.zst')   .then((json) => { res.lineends     = JSON.parse(json) }),
      unzstd(QuranPagesData + 'suarayat.json.zst')   .then((json) => { res.suarayat     = JSON.parse(json) }),
      unzstd(QuranPagesData + 'ayat.json.zst')       .then((json) => { res.ayat         = JSON.parse(json) }),
      unzstd(QuranPagesData + 'pauses.json.zst')     .then((json) => { res.pauses       = JSON.parse(json) }),
      unzstd(QuranPagesData + 'morepauses.json.zst') .then((json) => { res.morepauses   = JSON.parse(json) }),
      unzstd(QuranPagesData + 'allmeta.json.zst')    .then((json) => { Object.assign(res, JSON.parse(json)) }),
  ]).then(() => {
    resourcesLoaded = true
  })
}

// main logic

loadResources().then(() => {
  console.log('loaded; we have', res.words.length, 'pages')
})

// or

(async () => {

  // inside an async function
  await loadResources()
  console.log('loaded; we have', res.words.length, 'pages')

})()
```

## License

The images are the copyright of their original authors at Dar-ul-Ma‘refa (<https://www.easyquran.com/>). Any derivatives I present here are still their copyright.

All the code and data I present here (except the images) are my own work and are distributed under the terms of Creative Commons Zero (equivalent to Public Domain).

Copyright (c) 2025-2026 Noureddin.
