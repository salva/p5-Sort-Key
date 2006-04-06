package Sort::Key::Natural;

our $VERSION = '0.01';

require Exporter;

our @ISA = qw( Exporter );
our @EXPORT_OK = qw( natkeysort
		     natkeysort_inplace
		     rnatkeysort
		     rnatkeysort_inplace
		     mkkey_natural );

sub mkkey_natural {
    my $nat = @_ ? shift : $_;

    my @parts = $nat =~ /\d+|[[:alpha:]]+/g;
    for (@parts) {
	if (/^\d/) {
	    s/^0+//;
	    my $len = length;
	    my $nines = int ($len / 9);
	    my $rest = $len - 9 * $nines;
	    $_ = ('9' x $nines) . $rest . $_;
	}
    }
    return join("\0", @parts);
}

use Sort::Key::Register natural => \&mkkey_natural, 'string';
use Sort::Key::Register nat => \&mkkey_natural, 'string';

use Sort::Key::Maker natkeysort => 'nat';
use Sort::Key::Maker rnatkeysort => '-nat';
1;

=head1 NAME

Sort::Key::Natural - fast natural sorting

=head1 SYNOPSIS

    use Sort::Key::Natural 'natkeysort';

    my @data = qw(foo1 foo23 foo6 bar12 bar1
		  foo bar2 bar-45 b-a-r-45);

    my @sorted = natkeysort { $_ } @data;

    print "@sorted\n";
    # prints:
    #   b-a-r-45 bar1 bar2 bar12 bar-45 foo foo1 foo6 foo23

=head1 DESCRIPTION

This module extends the Sort::Key family of modules to support natural
sorting.

Under natural sorting, strings are splitted in word and number
boundaries, and the resulting substrings are compared as follows:

=over 4

=item *

numeric substrings are compared numerically

=item *

alphabetic substrings are compared lexically

=item *

numeric substrings come always before alphabetic substrings

=back

Spaces, symbols and non-printable characters are only considered for
splitting the string into its parts but not for sorting. For instance
C<foo-bar-42> is broken in three substrings C<foo>, C<bar> and C<42>
and after that the dashes are ignored.

Once this module is loaded, the new type C<natural> (or C<nat>) will
be available from L<Sort::Key::Maker>. For instance:

  use Sort::Key::Natural;
  use Sort::Key::Maker i_rnat_keysort => qw(integer -natural);

creates a multikey sorter C<i_rnat_keysort> accepting two keys, the
first to be compared as an integer and the second in natural
descending order.

=head2 FUNCTIONS

the functions that can be imported from this module are:

=over 4

=item natkeysort { CALC_KEY($_) } @data;

returns the elements on C<@array> naturally sorted by the key
resulting from applying C<CALC_KEY> to them.

=item rnatkeysort { CALC_KEY($_) } @data;

is similar to C<natkeysort> but sorting the elements on descending
order.

=item natkeysort_inplace { CALC_KEY($_) } @data;

=item rnatkeysort_inplace { CALC_KEY($_) } @data;

these functions are similar to C<natsortkey> and C<rnatsortkey> but
sort the array C<@data> in place.


=item mkkey_natural $key

transforms key C<$key> in a way that when sorted with L<Sort::Key>
keysort results in a natural sort. If the argument C<$key> is not
provided it defaults to C<$_>

=back

=head1 SEE ALSO

L<Sort::Key>, L<Sort::Key::Maker>.

Other module providing similar functionality is L<Sort::Natural>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Salvador FandiE<ntilde>o,
E<lt>sfandino@yahoo.comE<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
