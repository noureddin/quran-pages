#!/usr/bin/env perl
use v5.16; use warnings; use utf8;
use open qw[ :encoding(UTF-8) :std ];
use List::Util qw[ min any ];

$|++;  # autoflush stdout

# utils etc
use JSON::PP;  # core library
my $JSON = JSON::PP->new->utf8;
#
# sort keys of objects
my %order = ( name => 1, bism => 2 );  # headers
$JSON->sort_by(sub {
  my ($a, $b) = ($JSON::PP::a, $JSON::PP::b);
  return
    exists $order{$a} && exists $order{$b}  # if I have an order
      ? $order{$a} <=> $order{$b}
      :
    "$a$b" =~ /^[0-9]+$/  # if both are numeric
      ? $a <=> $b  # then compare numerically
      : $a cmp $b  # else compare alphabetically
});
#
sub slurp(_) { local $/; open my $f, '<', $_[0] or die "Couldn't open file '$_[0]' for reading: $!\n"; return scalar <$f> }
sub eject { my ($p,$t) = @_; open my $f, '>', $p or die "Couldn't open file '$p' for writing: $!\n"; print { $f } $t; }
#
sub read_json { my ($filepath) = @_; return $JSON->decode(slurp $filepath) }
sub write_json { my ($filepath, $content) = @_; eject $filepath, $JSON->encode($content) }

sub write_json_number_of { my ($basename, $json) = @_;
  my $all = $json // read_json "$basename.json";
  my @nn = map { scalar @$_ } @$all;
  write_json "numberof$basename.json", \@nn;
  return @nn;
}

# let's re-invent Make

my $force = grep /^-f$|^-B$/, @ARGV;

sub newer_than {
  return 1 if $force;
  my @new = @{$_[0]};  # output
  my @old = @{$_[1]};  # input
  return (any { !-e } @new)
      || (min map { -M $_ } @new) > (min map { -M $_ } @old);
}

################################################################################
# generate numberofayat.json from ayat.json

if (newer_than ['numberofayat.json'] => ['ayat.json']) {
  print 'Writing numberofayat.json... ';
  write_json_number_of 'ayat';
  say 'done';
}

################################################################################

# a word is the tuple [x,y,width,height].
# words.json is an array of pages, where each page is an array of words.
# lineends.json is an array of pages, where each page is an array of words,
#   each of which is the last word in its line.

my $need_lineends = newer_than ['lineends.json'] => ['words.json'];
my $need_numwords  = newer_than ['numberofwords.json'] => ['words.json'];

my $need_headers = newer_than ['headers.json', 'basmalaat.json']
                              => ['suarstarts.json', 'words.json'];
# 'words' because calculating suar names (headers) depends on the number of words in a page

if (!$need_headers && !$need_numwords && !$need_lineends) { exit }

my @words;

if ($need_lineends || $need_numwords) {
  print 'Reading words.json... ';
  @words = @{read_json 'words.json'};
  say 'done';
}

################################################################################
# generate lineends.json from words.json

if ($need_lineends) {
  print 'Writing lineends.json... ';
  my @lineends;
  for my $_p (@words) {
    my $last;
    my @page;
    for my $i (0..$#$_p) {
      my $w = $_p->[$i];
      # first word in page, or first word in a line
      if (!$last || $w->[0] > $last->[0]) {
        push @page, $i-1 if $last;
      }
      # any other word, including last word in page
      $last = $w;
    }
    push @page, $#$_p;  # the last word in page
    push @lineends, [@page];  # all the lines of the current page
  }
  write_json 'lineends.json', \@lineends;
  say 'done';
}

################################################################################
# generate numberofwords.json from words.json

my @nw;

if ($need_numwords) {
  print 'Writing numberofwords.json... ';
  @nw = write_json_number_of 'words', \@words;
}
elsif ($need_headers) {
  print 'Reading numberofwords.json... ';
  @nw = @{read_json 'numberofwords.json'};
}
say 'done';

@words = ();

################################################################################
# generate headers.json, and basmalaat.json from suarstarts.json

# mapping each page to the "words" that are actually "headers" (suar names) or basmalaat.

if (!$need_headers) { exit }

print 'Writing headers.json and basmalaat.json... ';

my @headers   = map { [] } 1..604;
my @basmalaat = map { [] } 1..604;

sub add_bism { my ($p, $w) = @_;
  push @{$basmalaat[$p-1]}, $w;
}

sub add_name { my ($p, $w) = @_;
  push @{$headers[$p-1]}, $w;
}

for my $start (@{read_json 'suarstarts.json'}) {
  my ($p, $w) = @$start;  # $p is 1-based, but $w is 0-based

  # Al-Fātiħa (sura 1) and at-Tawba (sura 9) have no additional basmala.
  # The basmala of al-Fātiħa is its first ayah, not separate.
  # Applications usually need that differentiation, eg, for audio.
  if ($p != 1 && $p != 187) {
    add_bism $p, $w;
  }

  # A sura header is always the previous "word".
  if ($w > 0) {
    add_name $p, $w-1;
  }
  else {  # the last word of the previous page. Remember: $p is 1-based, but @nw is an array, thus 0-based;
    add_name $p-1, $nw[$p-2]-1;
  }
}

write_json 'headers.json',   \@headers;
write_json 'basmalaat.json', \@basmalaat;
say 'done';
