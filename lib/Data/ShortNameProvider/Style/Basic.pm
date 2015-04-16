package Data::ShortNameProvider::Style::Basic;

use POSIX qw( strftime );

use Moo;
use namespace::clean;

with 'Data::ShortNameProvider::Role::Style';

has version => (
    is      => 'ro',
    default => '1',
);

has prefix => (
    is      => 'ro',
    default => 'dsnp',
);

# derived attributes

has timestamp => (
    is       => 'lazy',
    init_arg => undef,
    clearer  => 1,
    builder  => sub { strftime '%y%m%d', gmtime shift->timestamp_epoch; },
);

has parsing_regexp => (
    is       => 'lazy',
    init_arg => undef,
    clearer  => 1,
    builder  => sub {
        my ($self) = @_;
        my $re = quotemeta(    # who knows what attributes we have?
            $self->prefix
              . $self->version . '_'
              . strftime( '%y%m%d', gmtime $self->timestamp_epoch ) . '__'
        ) . '(.*)';
        return qr/^$re$/;
    },
);

around timestamp_epoch => sub {
    my $orig = shift;
    my $self = shift;

    # clear stuff that depend on timestamp_epoch
    $self->clear_timestamp;
    $self->clear_parsing_regexp;

    $orig->( $self, @_ );
};

sub generate_new_name {
    my ( $self, $name ) = @_;
    return
        $self->prefix
      . $self->version . '_'
      . strftime( '%y%m%d', gmtime( $self->timestamp_epoch ) ) . '__'
      . $name;
}

sub parse_generated_name {
    my ( $self, $short_name ) = @_;
    return if $short_name !~ $self->parsing_regexp;
    return {
        prefix          => $self->prefix,
        version         => $self->version,
        timestamp       => $self->timestamp,
        timestamp_epoch => $self->timestamp_epoch,
        name            => $1,
    };
}

1;
