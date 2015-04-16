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
          if !$class->does('Data::ShortNameProvider::Role::Style');

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

for my $method (
    qw(
    parse_generated_name
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

=head1 SYNOPSIS

Create a name provider:

    $np = Data::ShortNameProvider->new(
        style => 'Basic', # eg a subclass to allow alternative providers
        prefix => 'dbit',
        timestamp_format => 'YYMMDD',
        max_name_length => 32, # croak if a longer name is generated
    );


Generate a shortname:

    $name = $np->generate_new_name('foo'); # eg returns "dbit1_140513__foo"

The 'Basic' format would be: $prefix $version _ $timestamp __ $name.


Parse a generated shortname:

    $hash = $np->parse_generated_name($name); # eg to get date etc

%$hash would contain something like

    {
        version => 1, # version of the Basic format
        timestamp_string => '140513',
        timestamp_epoch => 1400017536,
        name => 'foo'
    }

or else undef if $name could not be parsed as a Basic style short name.


Check if a string is parsable:

    my @names = grep { $np->is_generated_name($_) } @names;

A faster check than calling parse_generated_name would be (eg it would
skip calculating timestamp_epoch).

I think parse_generated_name() and is_generated_name() should be strict
about matching only names that generate_new_name() would have generated
for the same attributes to new(). E.g. the specific timestamp_format.

=head1 DESCRIPTION

Create short names that encode a timestamp and a fixed prefix in a
format that's unlikely to match normal names.

A typical use-case would be the creation of database table names or
file names in situations where you need to minimize the risk of
clashing with existing items.

The generated names can be detected and parsed to extract the
timestamp.

