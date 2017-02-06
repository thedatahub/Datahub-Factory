package Datahub::Factory::Logger;

use Datahub::Factory::Sane;

use Moo::Role;
use MooX::Aliases;
use namespace::clean;

with 'MooX::Role::Logger';

alias log => '_logger';

1;

__END__
