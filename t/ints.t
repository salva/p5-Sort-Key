#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;
use Sort::Key qw(nkeysort rnkeysort nsort rnsort);

my @data=map { rand(20)-10 } 1..10000;

use integer;
is_deeply([nkeysort {$_} @data], [sort {$a<=>$b} @data], 'i id');
is_deeply([nkeysort {$_*$_} @data], [sort {$a*$a <=> $b*$b} @data], 'i sqr');
is_deeply([rnkeysort {$_*$_} @data], [sort {$b*$b <=> $a*$a} @data], 'ri sqr');
is_deeply([rnsort @data], [sort { $b <=> $a } @data], 'i rnsort');
is_deeply([nsort @data], [sort { $a <=> $b } @data], 'i nsort');
