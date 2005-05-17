#!/usr/bin/perl

use Test::More tests => 4;
use Sort::Key qw(nkeysort rnkeysort nkeysort_inplace);

use strict;
use warnings;

my @data=map { rand(200)-100 } 1..10000;

is_deeply([nkeysort {$_*$_} @data], [sort {$a*$a <=> $b*$b} @data], 'i sqr');

my @sorted=sort {$a<=>$b} @data;
is_deeply([nkeysort {$_} @data], \@sorted, 'n id');
is_deeply([rnkeysort {$_} @data], [reverse @sorted], 'reverse');
nkeysort_inplace {$_} @data;
is_deeply(\@data, \@sorted, 'in place')
