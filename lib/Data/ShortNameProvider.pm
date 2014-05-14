package Data::ShortNameProvider;

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

