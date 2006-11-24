package Sort::Key;

our $VERSION = '1.27';

use 5.006;

use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw( nsort nsort_inplace
		     isort isort_inplace
		     usort usort_inplace
		     rsort rsort_inplace
		     rnsort rnsort_inplace
		     risort risort_inplace
		     rusort rusort_inplace

		     keysort keysort_inplace
		     rkeysort rkeysort_inplace
		     nkeysort nkeysort_inplace
		     rnkeysort rnkeysort_inplace
		     ikeysort ikeysort_inplace
		     rikeysort rikeysort_inplace
		     ukeysort ukeysort_inplace
		     rukeysort rukeysort_inplace

		     multikeysorter multikeysorter_inplace);

require XSLoader;
XSLoader::load('Sort::Key', $VERSION);

our $DEBUG;
$DEBUG ||= 0;

# this hash is also used from Sort::Key::Multi to find out which
# letters can be used as types:
our %mktypes = ( s => 0,
                 l => 1,
                 n => 2,
                 i => 3,
                 u => 4 );

sub _mks2n {
    if (my ($rev, $key)=$_[0]=~/^([-+]?)(.)$/) {
	exists $mktypes{$key}
	    or croak "invalid multikey type '$_[0]'";
	my $n = $mktypes{$key};
	$n+=128 if $rev eq '-';
	return $n
    }
    die "internal error, bad key '$_[0]'";
}

our %mkmap = qw(str s
		string s
		locale l
		loc l
		lstr l
		int i
		integer i
		uint u
		unsigned_integer u
		number n
		num n);

$_ = [$_] for (values %mkmap);
our %mksub = map { $_ => undef } keys %mkmap;

sub _get_map {
    my ($rev, $name) = $_[0]=~/^([+-]?)(.*)$/;
    exists $mkmap{$name}
	or croak "unknown key type '$name'\n";
    if ($rev eq '-') {
	return map { /^-(.*)$/ ? $1 : "-$_" } @{$mkmap{$name}}
    }
    @{$mkmap{$name}}
}

sub _get_sub {
    $_[0]=~/^[+-]?(.*)$/;
    exists $mksub{$1}
	or croak "unknown key type '$1'\n";
    return $mksub{$1}
}

sub _combine_map { map { _get_map $_ } @_ }

use constant _nl => "\n";

sub _combine_sub {
    my $sub = shift;
    my $for = shift;
    $for = defined $for ? " for $for" : "";

    my @subs = map { _get_sub $_ } @_;

    if ($sub) {
	my $code = 'sub { '._nl;
	if (ref $sub eq 'CODE') {
	    unless (grep { defined $_ } @subs) {
		return $sub
	    }
	    $code.= 'my @keys = &{$sub};'._nl;
	}
	else {
	    if ($sub eq '@_') {
		return undef unless grep {defined $_} @subs;
	    }
	    $code.= 'my @keys = '.$sub.';'._nl;
	}
	$code.= 'print "in: |@keys|\n";'._nl if $DEBUG;

	$code.= '@keys == '.scalar(@_)
	  . ' or croak "wrong number of keys generated$for '
	    . '(expected '.scalar(@_).', returned ".scalar(@keys).")";'._nl;

	{ # new scope so @map doesn't get captured
	    my @map = _combine_map @_;
	    if (@map==@_) {
		for my $i (0..$#_) {
		    if (defined $subs[$i]) {
			$code.= '{ local $_ = $keys['.$i.']; ($keys['.$i.']) = &{$subs['.$i.']}() }'._nl;
		    }
		}
		$code.='print "out: |@keys|\n";'._nl if $DEBUG;
		$code.='return @keys'._nl;
	    }
	    else {
		$code.='my @keys1;'._nl;
		for my $i (0..$#_) {
		    if (defined $subs[$i]) {
			$code.= '{ local $_ = shift @keys; push @keys1, &{$subs['.$i.']}() }'._nl;
		    }
		    else {
			$code.= 'push @keys1, shift @keys;'._nl;
		    }
		}
		$code.='print "out: |@keys1|\n";'._nl if $DEBUG;
		$code.='return @keys1'._nl;
	    }
	}
	$code.='}'._nl;
	print "CODE$for:\n$code----\n" if $DEBUG >= 2;
	my $map = eval $code;
	$@ and die "internal error: code generation failed ($@)";
	return $map;
    }
    else {
	@_==1 or croak "too many keys or keygen subroutine undefined$for";
	return @subs;
    }
}

sub register_type {
    my $name = shift;
    my $sub = shift;
    $name=~/^\w+(?:::\w+)*$/
	or croak "invalid type name '$name'";
    @_ or
	croak "too few keys";
    (exists $mkmap{$name} or exists $mktypes{$name})
	and croak "type '$name' already registered or reserved in ".__PACKAGE__;
    $mkmap{$name} = [ _combine_map @_ ];
    $mksub{$name} = _combine_sub $sub, $name, @_;
}

sub multikeysorter {
    my @keys = @_;
    if (ref $_[0] eq 'CODE') {
	my $keygen = shift;
	my $sub = _combine_sub($keygen, undef, @_);
	@_ or croak "too few keys";
	my $ptypes = pack('C*', (map { _mks2n $_ } _combine_map(@_)));
	# print "type 1\n";
	# return _multikeysorter($ptypes, $keygen);
	return _multikeysorter($ptypes, $sub, undef);
    }
    else {
	my $sub = _combine_sub('@_', undef, @_);
	@_ or croak "too few keys";
	my $ptypes = pack('C*', (map { _mks2n $_ } _combine_map(@_)));
	return _multikeysorter($ptypes, undef, $sub)
    }
}

sub multikeysorter_inplace {
    if (ref $_[0] eq 'CODE') {
	my $keygen = shift;
	my $sub = _combine_sub($keygen, undef, @_);
	@_ or croak "too few keys";
	my $ptypes = pack('C*', (map { _mks2n $_ } _combine_map(@_)));
	return _multikeysorter_inplace($ptypes, $sub, undef);
    }
    else {
	my $sub = _combine_sub('@_', undef, @_);
	@_ or croak "too few keys";
	my $ptypes = pack('C*', (map { _mks2n $_ } _combine_map(@_)));
	return _multikeysorter_inplace($ptypes, undef, $sub);
    }
}


1;

__END__

=head1 NAME

Sort::Key - the fastest way to sort anything in Perl

=head1 SYNOPSIS

  use Sort::Key qw(keysort nkeysort ikeysort);

  @by_name = keysort { "$_->{surname} $_->{name}" } @people;

  # sorting by a numeric key:
  @by_age = nkeysort { $_->{age} } @people;

  # sorting by a numeric integer key:
  @by_sons = ikeysort { $_->{sons} } @people;

=head1 DESCRIPTION

Sort::Key provides a set of functions to sort lists of values by some
calculated key value.

It is faster (usually B<much faster>) and uses less memory than other
alternatives implemented around perl sort function (ST, GRT, etc.).

Multikey sorting functionality is also provided via the companion
modules L<Sort::Key::Multi>, L<Sort::Key::Maker> and
L<Sort::Key::Register>.

=head2 FUNCTIONS

This module provides a large number of sorting subroutines but
they are all variations off the C<keysort> one:

  @sorted = keysort { CALC_KEY($_) } @data

that is conceptually equivalent to

  @sorted = sort { CALC_KEY($a) cmp CALC_KEY($b) } @data

and where C<CALC_KEY($_)> can be any expresion to extract the key
value from C<$_> (not only a subroutine call).

For instance, some variations are C<nkeysort> that performs a numeric
comparison, C<rkeysort> that orders the data in descending order,
C<ikeysort> and C<ukeysort> that are optimized versions of C<nkeysort>
that can be used when the keys are integers or unsigned integers
respectively, etc.

Also, inplace versions of the sorters are provided. For instance

  keysort_inplace { CALC_KEY($_) } @data

that is equivalent to

  @data = keysort { CALC_KEY($_) } @data

but being (a bit) faster and using less memory.

The full list of subroutines that can be imported from this module
follows:

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

works as keysort but compares the keys as integers (32 bits or more,
no checking is performed for overflows).

=item rikeysort { CALC_KEY } @array

works as ikeysort, but in reverse (or descending) order.

=item ukeysort { CALC_KEY } @array

works as keysort but compares the keys as unsigned integers (32 bits
or more).

For instance, it can be used to efficiently sort IP4 addresses:

  my @data = qw(1.2.3.4 4.3.2.1 11.1.111.1 222.12.1.34
                0.0.0.0 255.255.255.0) 127.0.0.1);

  my @sorted = ukeysort {
                   my @a = split /\./;
                   (((($a[0] << 8) + $a[1] << 8) + $a[2] << 8) + $a[3])
               } @data;

=item rukeysort { CALC_KEY } @array

works as ukeysort, but in reverse (or descending) order.

=item keysort_inplace { CALC_KEY } @array

=item nkeysort_inplace { CALC_KEY } @array

=item ikeysort_inplace { CALC_KEY } @array

=item ukeysort_inplace { CALC_KEY } @array

=item rkeysort_inplace { CALC_KEY } @array

=item rnkeysort_inplace { CALC_KEY } @array

=item rikeysort_inplace { CALC_KEY } @array

=item rukeysort_inplace { CALC_KEY } @array

work as the corresponding keysort functions but sorting the array
inplace.

=item rsort @array

=item nsort @array

=item rnsort @array

=item isort @array

=item risort @array

=item usort @array

=item rusort @array

=item rsort_inplace @array

=item nsort_inplace @array

=item rnsort_inplace @array

=item isort_inplace @array

=item risort_inplace @array

=item usort_inplace @array

=item rusort_inplace @array

are simplified versions of its keysort cousins. They use the own
values as the sorting keys.

For instance those constructions are equivalent:

  @sorted = nsort @foo;

  @sorted = nkeysort { $_ } @foo;

  @sorted = sort { $a <=> $b } @foo;


=item multikeysorter(@types)

=item multikeysorter_inplace(@types)

=item multikeysorter(\&genkeys, @types)

=item multikeysorter_inplace(\&genkeys, @types)

are the low level interface to the multikey sorting functionality
(normally, you should use L<Sort::Key::Maker> and
L<Sort::Key::Register> or L<Sort::Key::Multi> instead).

They get a list of keys descriptions and return a reference to a
multikey sorting subroutine.

Types accepted by default are:

  string, str, locale, loc, integer, int,
  unsigned_integer, uint, number, num

and support for additional types can be added via the non exportable
L<register_type> subroutine (see below) or the more friendly interface
available from L<Sort::Key::Register>.

Types can be preceded by a minus sign to indicate descending order.

If the first argument is a reference to a subroutine it is used as the
multikey extraction function. If not, the generated sorters
expect one as their first argument.

Example:

  my $sorter1 = multikeysorter(sub {length $_, $_}, qw(int str));
  my @sorted1 = &$sorter1(qw(foo fo o of oof));

  my $sorter2 = multikeysorter(qw(int str));
  my @sorted2 = &$sorter2(sub {length $_, $_}, qw(foo fo o of oof));


=item Sort::Key::register_type($name, \&gensubkeys, @subkeystypes)

registers a new datatype named C<$name> defining how to convert it to
a multikey.

C<&gensubkeys> should convert the object of type C<$name> passed on
C<$_> to a list of values composing the multikey.

C<@subkeystypes> is the list of types for the generated multikeys.

For instance:

  Sort::Key::register_type Person =>
                 sub { $_->surname,
                       $_->name,
                       $_->middlename },
                 qw(str str str);

  Sort::Key::register_type Color =>
                 sub { $_->R, $_->G, $_->B },
                 qw(int int int);

Once a datatype has been registered it can be used in the same way
as types supported natively, even for defining new types, i.e.:

  Sort::Key::register_type Family =>
                 sub { $_->man, $_->woman },
                 qw(Person Person);




=back


=head1 SEE ALSO

perl L<sort> function, L<integer>, L<locale>.

Companion modules L<Sort::Key::Multi>, L<Sort::Key::Register>,
L<Sort::Key::Maker> and L<Sort::Key::Natural>.

Other interesting Perl sorting modules are L<Sort::Maker> and
L<Sort::Natural>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005, 2006 by Salvador FandiE<ntilde>o,
E<lt>sfandino@yahoo.comE<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
