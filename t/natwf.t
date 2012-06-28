#!/usr/bin/perl

use strict;
use warnings;

# BEGIN {$Sort::Key::DEBUG=10};

use Test::More tests => 9;

use Sort::Key 'keysort';
use Sort::Key::Natural qw(natwfkeysort natwfsort rnatwfsort rnatwfkeysort mkkey_natural_with_floats
			  natwfsort_inplace natwfkeysort_inplace rnatwfsort_inplace
			  rnatwfkeysort_inplace);

my @data = qw(foo1.12 foo23.2 foo.2 foo0.2 foo.0.21 fo2.1 fo-2.1
              fo-2.3 fo-2.10 foo+6 foo6 bar12 bar1 bar2 bar-45
              b-a-r-45 bar fo+2b fo.2c fo+1.9 fo2a);


my $sorted = 'b-a-r-45 bar bar-45 bar1 bar2 bar12 fo-2.3 fo-2.1 fo-2.10 fo+1.9 fo2a fo+2b fo.2c fo2.1 foo0.2 foo.0.21 foo1.12 foo.2 foo+6 foo6 foo23.2';
my $rsorted = 'foo23.2 foo+6 foo6 foo.2 foo1.12 foo.0.21 foo0.2 fo2.1 fo.2c fo+2b fo2a fo+1.9 fo-2.1 fo-2.10 fo-2.3 bar12 bar2 bar1 bar-45 bar b-a-r-45';
my @sorted;

@sorted = keysort { mkkey_natural_with_floats } @data;
is("@sorted", $sorted, 'mkkey_natural_with_floats');

@sorted = natwfkeysort { $_ } @data;
is("@sorted", $sorted, 'natwfkeysort');

@sorted = natwfsort @data;
is("@sorted", $sorted, 'natwfsort');

@sorted = @data;
natwfsort_inplace @sorted;
is("@sorted", $sorted, 'notsort_inplace');

@sorted = @data;
natwfkeysort_inplace { $_ } @sorted;
is("@sorted", $sorted, 'natwfkeysort_inplace');

@sorted = rnatwfkeysort { $_ } @data;
is("@sorted", $rsorted, 'rnatwfkeysort');

@sorted = rnatwfsort @data;
is("@sorted", $rsorted, 'rnatwfsort');

@sorted = @data;
rnatwfsort_inplace @sorted;
is("@sorted", $rsorted, 'rnotsort_inplace');

@sorted = @data;
rnatwfkeysort_inplace { $_ } @sorted;
is("@sorted", $rsorted, 'rnatwfkeysort_inplace');

