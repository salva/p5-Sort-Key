# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Sort-Key.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
BEGIN { use_ok('Sort::Key') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

@data=map { rand(200)-100 } 1..10000;

is_deeply([keysort {$_} @data], [sort @data], 'id');
is_deeply([nkeysort {$_} @data], [sort {$a<=>$b} @data], 'n id');
is_deeply([nkeysort {$_ * $_} @data], [sort { $a*$a <=> $b*$b } @data], 'n sqr');
is_deeply([ikeysort {$_*$_} @data], [sort {int($a*$a) <=> int($b*$b)} @data], 'i sqr');
