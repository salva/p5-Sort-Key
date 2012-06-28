#!/usr/bin/perl

# Natural sorting with negative numbers

use strict;
use warnings;

sub mkkey_floatnat {
    my $nat = @_ ? shift : $_;
    my @parts = $nat =~ /[\-+]?\d+(?:\.\d*)?|[\-+]?\.\d+|\p{IsAlpha}+/g;
    for (@parts) {
	if (my ($sign, $number, $dec) = /^([+-]?)(\d*)(?:\.(\d*))?$/) {
            $number =~ s/^0+//;
            $dec = '' unless defined $dec;
            $dec =~ s/0+$//;
	    my $len = length $number;
	    my $nines = int ($len / 9);
	    my $rest = $len - 9 * $nines;
            $_ = ('9' x $nines) . $rest . $number . $dec . "\0";
            if ($sign eq '-') {
                tr/0123456789/9876543210/;
                $_ = "-$_";
            }
	}
    }
    return join("\0", @parts);
}

use Sort::Key::Maker floatnatsort => \&mkkey_floatnat, 'str';

print floatnatsort(<DATA>);

__DATA__

fo
foo
foo bar
foo-bar
foo-45
foo-50.2345
foo45.12
foo+45.45
foo0
foofoo
foo-30
foo+40
foo30
foo.40
foo.-25

foo-2.1
foo-2.2ba
foo-2.3fg
foo-1.1
foo-1.2a
foo-1.3

