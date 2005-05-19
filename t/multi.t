#!/usr/bin/perl

use strict;
use warnings;

# BEGIN {$Sort::Key::DEBUG=10};

use Test::More tests => 4;

use Sort::Key::Maker nrs_keysort => sub { length($_), $_ }, qw(num -str);
use Sort::Key::Register length => sub { length $_ }, qw(int);

sub random_str {
    my $l=int rand(30);
    pack("c*", map { 64+int(32*rand) } 0..$l);
}

my @data=map { random_str } 1..1000;
my @sorted = sort {length($a) <=> length($b) or $b cmp $a } @data;

is_deeply([nrs_keysort @data], \@sorted, 'nrs');
nrs_keysort_inplace @data;

is_deeply(\@data, \@sorted, 'nrs inplace');

sub random_pair { [ rand, rand] }
sub random_pair_pair { [random_pair, random_pair] };
my @pps=map {random_pair_pair} 1..10000;

my @ppss = sort { ( $a->[0][0] <=> $b->[0][0] or
		    $a->[0][1] <=> $b->[0][1] or
		    $a->[1][0] <=> $b->[1][0] or
		    $a->[1][1] <=> $b->[1][1] ) } @pps;

# BEGIN {$Sort::Key::DEBUG=10};
use Sort::Key::Register pair => sub { @{$_}[0,1] }, qw(num num);
use Sort::Key::Register pair_pair => sub { @{$_}[0,1] }, qw(pair pair);
use Sort::Key::Maker pp_keysort => sub { $_ }, 'pair_pair';

is_deeply([pp_keysort @pps], \@ppss, 'pps');
pp_keysort_inplace(@pps);
is_deeply(\@pps, \@ppss, 'pps inplace');
