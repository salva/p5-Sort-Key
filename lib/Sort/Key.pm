package Sort::Key;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.04';

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(keysort nkeysort);

require XSLoader;
XSLoader::load('Sort::Key', $VERSION);

use constant STR_SORT => 0;
use constant LOC_STR_SORT => 1;
use constant NUM_SORT => 2;
use constant INT_SORT => 3;

my ($int_hints, $locale_hints);
BEGIN {
    use integer;
    $int_hints = $integer::hint_bits || 0x1;

    use locale;
    $locale_hints = $locale::hint_bits || 0x4;

    # print STDERR "locale: $locale_hints, int: $int_hints\n";
}

sub keysort (&@) {
    my $k = shift;
    my @k = map { scalar(&{$k}) } @_;
    my $sort = ((caller(0))[8] & $locale_hints)
	? LOC_STR_SORT : STR_SORT;
    _keysort($sort, \@k, \@_);
    wantarray ? @k : $k[0];
}

sub nkeysort(&@) {
    my $k = shift;
    my @k;
    if ((caller(0))[8] & $int_hints) {
	use integer;
	@k = map { int(&{$k}) } @_;
	_keysort(INT_SORT, \@k, \@_);
    }
    else {
	@k = map { scalar(&{$k}) } @_;
	_keysort(NUM_SORT, \@k, \@_);
    }
    wantarray ? @k : $k[0];
}

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

Usually, it is faster and uses less memory than other alternatives implemented
around perl sort function.

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

=back


=head1 SEE ALSO

perl L<sort> function, L<integer>, L<locale>.

=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Salvador FandiE<ntilde>o

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
