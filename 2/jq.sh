#!/bin/bash

# # other probably useful representations of the data (using jq)

################################################################################

# # an array of pages whose elements are the dimensions (as in words.json) of suar names
# <words.json jq 'map(map(select(.[2] > 450)))'

# # a slightly more readable format for the same data (both commands have the same behavior, but the second maybe more portable)
# <words.json jq 'map(map(select(.[2] > 450)))' | sed '/^    \[/{N;N;N;N;N;s/\n */ /g}; s/\( [0-9][0-9],\)/ \1/g'
# <words.json jq 'map(map(select(.[2] > 450)))' | perl -0777 -pe 's/^ {4}(\[\n.*?\])/" "x4 . $1=~s|\n *| |gr/smge; s/( \d{2},)/ $1/g'

# # the takeaway: a sura name is always > 450px in width (the third (ie, [2]) element in the tuple of a word).

################################################################################
