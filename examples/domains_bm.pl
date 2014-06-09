#!/usr/bin/perl

use strict;
use warnings;
use Benchmark 'cmpthese';
use Sort::Key qw(keysort);
use HTTP::Tiny;

my $n = shift @ARGV // 100_000;

sub generate_weights {
    my $n = shift;
    my $w = 0;
    my @w;
    for (1..$n) {
        $w += (rand(1) ** 3);
        push @w, $w;
    }
    return @w;
}

sub weighted_rand {
    my $w = shift;
    my $r = rand($w->[-1]);
    my $i = 0;
    my $j = $#$w;
    while ($i < $j) {
        my $pivot = (($i + $j) >> 1);
        if ($w->[$pivot] > $r) {
            $j = $pivot;
        }
        else {
            $i = $pivot + 1;
        }
    }
    return $j;
}

$| = 1;
print "retrieving top level domains...\n";

my $res = HTTP::Tiny->new->get('http://data.iana.org/TLD/tlds-alpha-by-domain.txt');
$res->{success} or die "unable to retrieve list of top level domains";

my @top = map lc, grep /^\w+$/, split /\n+/, $res->{content};
my @top_w = generate_weights scalar @top;

open my $words, '<', '/usr/share/dict/words' or die "unable to open words file: $!";
my @words = grep /^[a-z]{3,}$/, <$words>;
chomp @words;
my @words_w = generate_weights scalar @words;

print "generating data...\n";
my @domain;
for (1..$n) {
    my $top = $top[weighted_rand \@top_w];
    push @domain, join '.', @words[map weighted_rand(\@words_w), 0..1 + rand 3], $top;
}

print "benchmarking...\n";
cmpthese (10, {
               grt => sub {
                   my @sorted = map { join '.', reverse split /\./ }
                                sort
                                map { join '.', reverse split /\./ } @domain;
               },
               js  => sub {
                   my @sorted  = map { (split /:/)[1] }
                                 sort
                                 map { join( '.', reverse split /\./ ) . ":$_" } @domain;
               },
               sk  => sub {
                   my @sorted = keysort { join '.', reverse split /\./ } @domain;
               },
              }
         );


__END__

Tipical output:

$ perl sort_domains.pl
retrieving top level domains...
generating data...
benchmarking...
      Rate  grt   js   sk
grt 1.20/s   -- -10% -23%
js  1.33/s  11%   -- -15%
sk  1.56/s  30%  17%   --


