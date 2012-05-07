#!/usr/bin/perl

# Natural sorting with negative numbers

use strict;
use warnings;

sub mkkey_negnat {
    my $nat = @_ ? shift : $_;
    my @parts = $nat =~ /[\-+]?\d+|\p{IsAlpha}+/g;
    for (@parts) {
	if (my ($sign, $number) = /^([+-]?)(\d+)/) {
            $number =~ s/^0+//;
	    my $len = length $number;
	    my $nines = int ($len / 9);
	    my $rest = $len - 9 * $nines;
            $_ = ('9' x $nines) . $rest . $number;
            if ($sign eq '-') {
                tr/0123456789/9876543210/;
                $_ = "-$_";
            }
	}
    }
    return join("\0", @parts);
}

use Sort::Key::Maker negnatsort => \&mkkey_negnat, 'str';

print negnatsort(<DATA>);

__DATA__

fo
foo
foo bar
foo-bar
foo-45
foo-50
foo45
foo+45
foo0
foofoo
foo-30
foo+40
foo30
foo.40
foo.-25

