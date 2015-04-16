package Data::ShortNameProvider;

use Carp;

use Moo;
use namespace::clean;

# attributes

has style => (
    is      => 'ro',
    default => 'Basic',
);

has max_name_length => (
    is       => 'ro',
    required => 1,
    default  => 32,
);

has provider => (
    is       => 'lazy',
    init_arg => undef,
    builder  => sub {
        my ($self) = shift;

        # allow style => '+My::Fully::Qualified::Style'
        my $style = $self->style;
        my $class =
            substr( $style, 0, 1 ) eq '+'
          ? substr( $style, 1 )
          : "Data::ShortNameProvider::Style::$style";
        eval "require $class;" or croak $@;

        croak "$class does not implement the Data::ShortNameProvider::Role::Style role"
          if !$class->DOES('Data::ShortNameProvider::Role::Style');

        return $class->new( $self->extra );
    },
);

# extra attributes passed to instantiate the delegate
# any value passed to the constructor will be ignored
# as it is populated by BUILDARGS from leftover arguments
has extra => ( is => 'ro' );

sub BUILDARGS {
    my $extra = Moo::Object::BUILDARGS(@_);
    my $args;    # expected arguments
    exists $extra->{$_} and $args->{$_} = delete $extra->{$_}
      for (qw( style nax_name_length ));
    $args->{extra} = $extra;    # arguments for the delegated style class
    return $args;
}

# ensure the provider is built during construction
sub BUILD { shift->provider }

#
# methods
#

sub style_class { ref shift->provider }

#
# most stuff is delegated to the provider
#

sub generate_new_name {
    my ( $self, $name ) = @_;
    my $short_name = $self->provider->generate_new_name($name);

    # enforce length restrictions
    if ( length($short_name) > $self->max_name_length ) {
        croak sprintf
          "%s (provided by %s) is longer than the %d bytes limit",
          $short_name, $self->style_class, $self->max_name_length;
    }

    return $short_name;
}

sub parse_generated_name {
    my ( $self, $name ) = @_;
    my $hash = $self->provider->parse_generated_name($name);
    $hash->{$_} = $self->$_
      for (qw( style max_name_length ));
    return $hash;
}

for my $method (
    qw(
    is_generated_name
    timestamp_epoch
    )
  )
{
    no strict 'refs';
    *$method = sub { shift->provider->$method(@_) };
}

1;

__END__

=for Pod::Coverage::TrustPod
 extra
 BUILDARGS

=head1 NAME

Data::ShortNameProvider - Generate short names with style

=head1 SYNOPSIS

Create a name provider:

    my $np = Data::ShortNameProvider->new(
        style           => 'Basic',       # default
        timestamp_epoch => 1400023019,    # defaults to time()
        max_name_length => 32,            # croak if a longer name is generated

        # style-specific arguments
        prefix  => 'dbit',
        version => 1,
    );

Generate a shortname:

    $short_name = $np->generate_new_name('foo');   # returns "dbit1_140513__foo"

Parse a generated shortname:

    $hash = $np->parse_generated_name($short_name);

C<$hash> contains something like:

    # depends on the style
    {
        prefix          => 'dbit',
        version         => 1,
        timestamp       => '140513',
        timestamp_epoch => 1400023019,
        name            => 'foo',
    }

or C<undef> if C<$short_name> could not be parsed as a short name generated
with that style.

Check if a string is parsable:

    my @names = grep { $np->is_generated_name($_) } @names;

=head1 DESCRIPTION

Create short names that encode a timestamp and a fixed label in a
format that's unlikely to match normal names.

A typical use-case would be the creation of database table names or
file names in situations where you need to minimize the risk of
clashing with existing items.

The generated names can be detected and parsed to extract the
timestamp and other components.

=head1 ATTRIBUTES

=head2 style

The style of the actual short name provider.

If prefixed with a C<+> sign, it's a fully-qualified class name,
otherwise, it will be prefixed with C<Data::ShortNameProvider::Style::>
to produce the fully-qualified style class name.

=head2 style_class

The fully-qualified name of the style class.

=head2 max_name_length

A maximum length constraint on the generated short names.

L</generate_new_name> will die if the "short name" returned by the style
is longer than C<max_name_length>.

=head2 provider

The instance of L</style_class> to which most of the actual work is
delegated.

=head1 METHODS

=head2 generate_new_name

    my $short_name = $dsnp->generate_new_name($name);

Delegated to the L</provider> object, but enforces some res

=head2 parse_generated_name

    my $hash = $dsnp->parse_generated_name($short_name);

Parses a name that was generated by the L</provider>, and returns its
constituents as a hash reference.

Delegates to the L</provider> object, and add the L</style> and
L</max_name_length> keys, so that one is always be able to make a copy
of the object by doing:

    my $clone = Data::ShortNameProvider->new($hash);

=head2 is_generated_name

    if( $dsnp->is_generated_name( $name ) ) { ... }

Return a boolean indicating if the C<$name> string could have been
generated by this provider.

Delegated to the L</provider> object.

=head2 timestamp_epoch

This is a read-write accessor to the provider's
L<timestamp_epoch|Data::ShortNameProvider::Role::Style/timestamp_epoch>
attribute.

Delegated to the L</provider> object.

=head1 ACKNOWLEDGEMENTS

This module is based on an idea and proposal by Tim Bunce, on the C<dbi-dev>
mailing-list.

The initial thread about L<Test::Database> shortcomings:
L<http://www.nntp.perl.org/group/perl.dbi.dev/2014/04/msg7792.html>

Tim's proposal for a short name provider:
L<http://www.nntp.perl.org/group/perl.dbi.dev/2014/05/msg7815.html>

The first implementaion of the module was written during the first day of
the Perl QA Hackathon 2015 in Berlin (with Tim Bunce providing feedback
on IRC). Many thanks to TINITA for organizing this event!

=head1 AUTHOR

Philippe Bruhat (BooK), <book@cpan.org>.

=head1 COPYRIGHT

Copyright 2014-2015 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
