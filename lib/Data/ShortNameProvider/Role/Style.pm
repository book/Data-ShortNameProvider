package Data::ShortNameProvider::Role::Style;

use Moo::Role;

requires
  'generate_new_name',
  'parse_generated_name',
  ;

has timestamp_epoch => (
    is      => 'rw',
    default => sub { time },
);

sub is_generated_name { !!shift->parse_generated_name(shift); }

1;
