#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

eval "use Test::Spelling";
plan skip_all => "Test::Spelling required for testing POD spelling" if $@;

my @ignore = ("Fandi\xf1o", "API", "CPAN", "GitHub",
              "lexicographically", "ri", "ru", "rn", "GRT",
              "ikeysort", "wishlist", "natively", "isort", "keysort",
              "nkeysort", "nsort", "rikeysort", "risort", "rnkeysort",
              "rnsort", "rsort", "rukeysort", "rusort", "ukeysort",
              "rusort", "ukeysort", "usort", "natkeysort",
              "natkeywfsort", "natsort", "natwfkeysort", "natwfsort",
              "rnatkeysort", "rnatsort", "rnatwfkeysort", "rnatwfsort"
              );

local $ENV{LC_ALL} = 'C';
add_stopwords(@ignore);
all_pod_files_spelling_ok();

