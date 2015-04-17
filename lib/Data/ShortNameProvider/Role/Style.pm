package Data::ShortNameProvider::Role::Style;

use Moo::Role;

requires
  'generate_name',
  'parse_generated_name',
  ;

has timestamp_epoch => (
    is      => 'ro',
    default => sub { time },
);

sub is_generated_name {
    # uncoverable subroutine
    # uncoverable statement
    !!shift->parse_generated_name(shift);
}

1;

__END__

=head1 NAME

Data::ShortNameProvider::Role::Style - Role for Data::ShortNameProvider styles

=head1 SYNOSPIS

Define your own style:

    package My::DSNP::Style;

    use Moo;

    with 'Data::ShortNameProvider::Role::Style';

    sub generate_name {
        my ( $self, $name ) = @_;
        return "short_$name";
    }

    sub parse_generated_name {
        my ( $self, $name ) = @_;
        return if not $self =~ /^short_(.*)$/;
        return { name => $1 };
    }

    1;

Use it:

    use Data::ShortNameProvider;

    my $np = Data::ShortNameProvider->new( style => '+My::DSNP::Style' );
    my $short_name = $np->generate_shortname($name);

=head1 DESCRIPTION

This role provides the basic attributes and requirements for a class
to be used as a style provider for L<Data::ShortNameProvider>.

L<Data::ShortNameProvider> actually checks if the provided style class
implements this role, and throws an exception if it doesn't.

=head1 PROVIDED ATTRIBUTES

=head2 timestamp_epoch

This is a timestamp in Unix epoch, that may be used by the style to
produce short names.

The default is the return value of C<time()>.

=head1 PROVIDED METHODS

Data::ShortNameProvider::Role::Style provides a default implementation
of some methods. Your style can provide its own version for efficiency
reasons.

=head2 is_generated_name

    if( $provider->is_generated_name( $name ) ) { ... }

Return a boolean indicating if the C<$name> string could have been
generated by this provider.

=head1 REQUIRED METHODS

=head2 generate_name

    my $short_name = $provider->parse_generated_name( $name );

Generate a "short name" for the C<$name> parameter.

=head2 parse_generated_name

    my $hash = $provider->parse_generated_name( $short_name );

Return the components of the name as a hash.
This method will parse names that might have been generated with a different
instance.

C<$hash> should at least contain the C<name> and C<timestamp_epoch> keys.
Everything else depends on the style itself, but one should always be
able to make a copy of the original provider by passing C<$hash> to the
constructor.

    my $prev = My::DSNP::Style->new(%args);
    my $sn   = $prev->generate_new_name($name);

    my $cur  = My::DSNP::Style->new(%other_args);
    my $hash = $cur->parse_generated_name($sn);

    my $next = My::DSNP::Style->new($hash);

    # always true
    $sn eq $next->generate_new_name($name);

=head1 SEE ALSO

L<Data::ShortNameProvider>,
L<Data::ShortNameProvider::Style::Basic>.

=head1 AUTHOR

Philippe Bruhat (BooK), <book@cpan.org>.

=head1 COPYRIGHT

Copyright 2014-2015 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
