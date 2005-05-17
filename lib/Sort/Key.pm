package Sort::Key;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.05';

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(keysort keysort_inplace
		    rkeysort rkeysort_inplace
		    nkeysort nkeysort_inplace
		    rnkeysort rnkeysort_inplace
		    ikeysort ikeysort_inplace
		    rikeysort rikeysort_inplace);

require XSLoader;
XSLoader::load('Sort::Key', $VERSION);

1;

__END__

=head1 NAME

Sort::Key - Perl extension for sorting objects by some key

=head1 SYNOPSIS

  use Sort::Key qw(keysort nkeysort ikeysort);
  
  @by_name = keysort { "$_->{surname} $_->{name}" } @people;
  @by_age = nkeysort { $_->{age} } @people;
  @by_sons = ikeysort { $_->{sons} } @people;

=head1 DESCRIPTION

Sort::Key provides a set of functions to sort object arrays by some
(calculated) key value.

It is faster and uses less memory than other alternatives implemented
around perl sort function (ST, GRM, etc.)

=head2 EXPORT

None by default.

Functions available from this module are:

=over 4

=item keysort { CALC_KEY } @array

returns the elements on C<@array> sorted by the key calculated
applying C<{ CALC_KEY }> to them.

Inside C<{ CALC_KEY }>, the object is available as C<$_>.

For example:

  @a=({name=>john, surname=>smith}, {name=>paul, surname=>belvedere});
  @by_name=keysort {$_->{name}} @a;

This function honours the C<use locale> pragma.

=item nkeysort { CALC_KEY } @array

similar to keysort but compares the keys numerically instead of
as strings.

This function honours the C<use integer> pragma, i.e.:

  use integer;
  my @s=(2.4, 2.0, 1.6, 1.2, 0.8);
  my @ns = nkeysort { $_ } @s;
  print "@ns\n"

prints

  0.8 1.6 1.2 2.4 2

=item rnkeysort { CALC_KEY } @array

works as nkeysort, comparing keys in reverse (or descending) numerical order.

=item ikeysort { CALC_KEY } @array

works as keysort but compares the keys as integers.

=item rikeysort { CALC_KEY } @array

works as ikeysort, but in reverser (descending order).

=item keysort_inplace { CALC_KEY } @array

=item nkeysort_inplace { CALC_KEY } @array

=item ikeysort_inplace { CALC_KEY } @array

=item rkeysort_inplace { CALC_KEY } @array

=item rnkeysort_inplace { CALC_KEY } @array

=item rikeysort_inplace { CALC_KEY } @array

work as the corresponding keysort functions but sorting the array
inplace.

=back


=head1 SEE ALSO

perl L<sort> function, L<integer>, L<locale>.

And alternative to this module is L<Sort::Maker>.

=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Salvador FandiE<ntilde>o

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
