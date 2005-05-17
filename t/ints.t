#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Sort::Key qw(nkeysort);

my @data=map { rand(20)-10 } 1..10000;

use integer;
is_deeply([nkeysort {$_} @data], [sort {$a<=>$b} @data], 'n id');
is_deeply([nkeysort {$_*$_} @data], [sort {$a*$a <=> $b*$b} @data], 'i sqr');

