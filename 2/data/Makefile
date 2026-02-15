all:
	perl generate.pl -$(MAKEFLAGS)
	bash make.sh -$(MAKEFLAGS)

onlywords:
	< words.json tr -d $$' \n' | zstd -1 > words.json.zst

.PHONEY: all
