package Sort::Key;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.01';

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(keysort lkeysort nkeysort ikeysort);

require XSLoader;
XSLoader::load('Sort::Key', $VERSION);

sub cr (&@) {
  my $sub=shift;
  my $t0=times;
  my @r=&$sub(@_);
  my $t1=times;
  printf STDERR "dt=%f\n", ($t1-$t0)
}

sub keysort (&@) {
    my $k = shift;
    my @k = map { scalar(&{$k}) } @_;
    _keysort(0, \@k, \@_);
    wantarray ? @k : $k[0];
}

sub lkeysort(&@) {
    my $k = shift;
    my @k = map { scalar(&{$k}) } @_;
    _keysort(1, \@k, \@_);
    wantarray ? @k : $k[0];
}

sub nkeysort (&@) {
    my $k = shift;
    my @k = map { scalar(&{$k}) } @_;
    _keysort(2, \@k, \@_);
    wantarray ? @k : $k[0];
}

sub ikeysort(&@) {
    my $k = shift;
    my @k = map { int(&{$k}) } @_;
    _keysort(3, \@k, \@_);
    wantarray ? @k : $k[0];
}

1;

__END__

=head1 NAME

Sort::Key - Perl extension for sorting objects by some key

=head1 SYNOPSIS

  use Sort::Key;
  
  @by_name = keysort { "$_->{surname} $_->{name}" } @people;
  @by_age = nkeysort { $_->{age} } @people;
  @by_sons = ikeysort { $_->{sons} } @people;

=head1 DESCRIPTION

Sort::Key provides a set of functions to sort object arrays by some
(calculated) key value.

Usually, it is faster and uses less memory than other alternatives implemented
around perl sort function.

=head2 EXPORT

This package exports these functions:

=over 4

=item keysort { CALC_KEY } @array

sorts C<@array> by the key calculated applying C<{ CALC_KEY }>.

Inside C<{ CALC_KEY }>, the object is available as C<$_>.

For example:

  @a=({name=>john, surname=>smith}, {name=>paul, surname=>belvedere});
  @by_name=keysort {$_->{name}} @a;

=item lkeysort { CALC_KEY } @array

similar to keysort but takes into account locale configuration
when comparing keys.

=item nkeysort { CALC_KEY } @array

similar to keysort but compares the keys numerically instead of
as strings.

=item ikeysort { CALC_KEY } @array

similar to keysort but automatically converts the keys to integer
values and compares them numerically.

=back


=head1 SEE ALSO

perl L<sort> function

=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Salvador FandiE<ntilde>o

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
