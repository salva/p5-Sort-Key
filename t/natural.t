#!/usr/bin/perl

use strict;
use warnings;

# BEGIN {$Sort::Key::DEBUG=10};

use Test::More tests => 2;

use Sort::Key 'keysort';
use Sort::Key::Util 'mkkey_natural';
use Sort::Key::Natural 'natkeysort';

my @data = qw(foo1 foo23 foo foo foo fo2 foo6 bar12
	      bar1 bar2 bar-45 b-a-r-45 bar);

my @sorted = keysort { mkkey_natural } @data;
my @sorted1 = natkeysort { $_ } @data;

is("@sorted", 'b-a-r-45 bar bar1 bar2 bar12 bar-45 fo2 foo foo foo foo1 foo6 foo23', 'natural sort');
is("@sorted1", 'b-a-r-45 bar bar1 bar2 bar12 bar-45 fo2 foo foo foo foo1 foo6 foo23', 'natural sort');
