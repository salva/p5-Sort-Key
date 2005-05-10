#!/usr/bin/perl

use Test::More tests => 5;
BEGIN { use_ok('Sort::Key') };

use Sort::Key qw(keysort nkeysort ikeysort);

@data=map { rand(200)-100 } 1..10000;

is_deeply([keysort {$_} @data], [sort @data], 'id');
is_deeply([nkeysort {$_} @data], [sort {$a<=>$b} @data], 'n id');
is_deeply([nkeysort {$_ * $_} @data], [sort { $a*$a <=> $b*$b } @data], 'n sqr');
is_deeply([ikeysort {$_*$_} @data], [sort {int($a*$a) <=> int($b*$b)} @data], 'i sqr');
