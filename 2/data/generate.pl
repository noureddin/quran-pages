#!/usr/bin/env perl
use v5.18; use warnings; use utf8;
use open qw[ :encoding(UTF-8) :std ];
use List::Util qw[ min any ];

no warnings "experimental::lexical_subs";
use feature 'lexical_subs';

use JSON::PP;  # core library
my $JSON = JSON::PP->new->utf8;
$JSON->sort_by(sub {
  my ($a, $b) = ($JSON::PP::a, $JSON::PP::b);
  return
    "$a$b" =~ /^[0-9]+$/  # if both are numeric
      ? $a <=> $b  # then compare numerically
      : $a cmp $b  # else compare alphabetically
});

sub slurp(_) { local $/; open my $f, '<', $_[0] or die "Couldn't open file '$_[0]' for reading: $!\n"; return scalar <$f> }
sub eject { my ($p,$t) = @_; open my $f, '>', $p or die "Couldn't open file '$p' for writing: $!\n"; print { $f } $t; }

sub read_json { my ($filepath) = @_; return $JSON->decode(slurp $filepath) }
sub write_json { my ($filepath, $content, $fmt) = @_; eject $filepath, ($fmt // sub { $_[0] })->($JSON->encode($content)) }

$|++;  # autoflush stdout for printing progress messages

# let's re-invent Make

my $force = grep /^-f$|^-B$/, @ARGV;  # the only cli option we accept

sub newer_than {
  return 1 if $force;
  my @new = @{$_[0]};  # output
  my @old = @{$_[1]};  # input
  for (@old) { die "ERROR: input file needed but nonexistent: $_\n" unless -e $_ }
  return (any { !-e } @new)
      || (min map { -M $_ } @new) > (min map { -M $_ } @old);
}

my %in;

sub numberof { my ($name, $keep) = @_;
  return { out => "numberof$name", in => $name, do => sub {
    my $num = [map { scalar @$_ } @{$in{$name}}];
    if ($keep) { $in{"numberof$name"} = $num };
    write_json "numberof$name.json", $num, sub { $_[0]
      =~ s/(?:[\[,][0-9]+){20}/$&\n/gr
      =~ s/(?<![0-9])[0-9](?![0-9])/  $&/gr
      =~ s/(?<![0-9])[0-9]{2}(?![0-9])/ $&/gr
      =~ s/\]/ $&/gr
    };
  } }
}

my @rules = (

################################################################################

numberof('ayat'),

numberof('words', 1),  # store it in %in, because it's needed later

################################################################################

{ out => 'suarayat', in => 'ayat suarstarts', do => sub {
    my @suarstart_by_page;

    for my $start (@{$in{suarstarts}}) {
      my ($p, $w) = @$start;  # $p is 1-based, but $w is 0-based
      push @{$suarstart_by_page[$p-1]}, $w;
    }

    my @sa;

    for my $p (1..604) {
      my @sbgn = @{$suarstart_by_page[$p-1] // []};
      my @aend = @{$in{ayat}[$p-1]};

      while (@sbgn || @aend) {
        if (@sbgn && $sbgn[0] < $aend[0]) {
          my $a0 = shift @sbgn;
          push @sa, [ [$p, $a0] ];
          # printf "\e[93m%d\e[m ", $a0;
        }
        else {
          my $aa = 1 + shift @aend;
          push @{$sa[-1]}, [$p, $aa];
          # printf "\e[95m%d\e[m ", $aa;
        }
      }

      # printf "\n";
    }

    write_json 'suarayat.json', \@sa, sub { $_[0]
      =~ s/\]\](?=,)/]]\n/gr
      =~ s/(\[([0-9]+),[0-9]+\])(?=,\[([0-9]+),)/$2 ne $3 ? "$1\n  " : "$1"/gre
      =~ s/([,\[])(?=\[)/$1 /gr
      =~ s/(?<![0-9])[0-9]{1}(?![0-9])/  $&/gr
      =~ s/(?<![0-9])[0-9]{2}(?![0-9])/ $&/gr
      =~ s/\](?=\])/] /gr
    };
  } },

################################################################################

# a word is the tuple [x,y,width,height].
# words.json is an array of pages, where each page is an array of words.
# lineends.json is an array of pages, where each page is an array of words,
#   each of which is the last word in its line.

{ out => 'lineends', in => 'words', do => sub {
    my @lineends;

    for my $_p (@{$in{words}}) {
      my $last;
      my @page;

      for my $i (0..$#$_p) {
        my $w = $_p->[$i];
        # first word in page, or first word in a line
        if (!$last || $w->[1] > $last->[1] + $last->[3] - 15) {
          push @page, $i-1 if $last;
        }
        # any other word, including last word in page
        $last = $w;
      }

      push @page, $#$_p;  # the last word in page
      push @lineends, [@page];  # all the lines of the current page
    }

    write_json 'lineends.json', \@lineends, sub { $_[0]
      =~ s/[\[\]]/ $&/gr =~ s/^ //gr
      =~ s/, \[/\n, [/gr
      =~ s/(?<![0-9])[0-9]{1}(?![0-9])/   $&/gr
      =~ s/(?<![0-9])[0-9]{2}(?![0-9])/  $&/gr
      =~ s/(?<![0-9])[0-9]{3}(?![0-9])/ $&/gr
    };
  } },

################################################################################

# Note: numberofwords is an output, but because @rules is ordered,
#   numberofwords must be computed or read at this point.

{ out => 'headers basmalaat', in => 'suarstarts numberofwords', do => sub {
    # mapping each page to the "words" that are actually "headers" (suar names) or basmalaat.

    my @headers   = map { [] } 1..604;
    my @basmalaat = map { [] } 1..604;

    my sub add_bism { my ($p, $w) = @_;
      push @{$basmalaat[$p-1]}, $w;
    }

    my sub add_name { my ($p, $w) = @_;
      push @{$headers[$p-1]}, $w;
    }

    for my $start (@{$in{suarstarts}}) {
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
      else {  # the last word of the previous page. Remember: $p is 1-based, but $in{numberofwords} is an array, thus 0-based;
        add_name $p-1, $in{numberofwords}[$p-2]-1;
      }
    }

    my $residue;
    my $fmt = sub { $_[0]
      =~ s/(?:[\[,][^\]]+]){20}/$&\n/gr
      =~ s/\[\[/[ [/gr
      =~ s/\]\]/] ]/gr
      =~ s/,\[/, [/gr
      =~ s{([,\[]) \[(.*?)\]}{
        my $padlength = 4;
        my $needed = length $2;
        if (defined $residue) { $padlength -= $residue; $residue = undef }
        $padlength -= $needed;
        if ($padlength < 0) { $residue = -$padlength; $padlength = 0 }
        $1 . " "x$padlength . "[$2]"
      }gre
      =~ s/\Z/$residue = undef; ""/gre
      # =~ s/, \[(.*?)\]/", [$1]" . " "x(7 - length $1)/gre
    };

    write_json 'headers.json',   \@headers,   $fmt;
    write_json 'basmalaat.json', \@basmalaat, $fmt;
  } },
);

################################################################################

my $t = -t STDIN && -t STDOUT;  # if an interactive terminal
sub rgb {
  my ($r,$g,$b) = map { $_ % 6 } shift, shift, shift;
  my $c = 16 + 36*$r + 6*$g + $b;
  my $f = shift;
  if ($t) { $f = "\e[38;5;${c}m" . $f . "\e[m" }
  return $f, @_;
}

for my $r (@rules) {
  my @inp = map "$_.json", split / /, $r->{in};
  my @out = map "$_.json", split / /, $r->{out};
  next unless newer_than \@out => \@inp;
  #
  for my $i (split / /, $r->{in}) {
    next if exists $in{$i};
    print rgb 5,3,5, "← Reading $i.json... ";
    $in{$i} = read_json "$i.json";
    say rgb 2,5,2, "done ✓";
  }
  #
  printf rgb 1,5,5, "→ Writing %s... ", join " and ", @out;
  $r->{do}();
  say rgb 2,5,2, "done ✓";
}
