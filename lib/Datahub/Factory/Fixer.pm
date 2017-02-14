package Datahub::Factory::Fixer;

use Datahub::Factory::Sane;

use Moo;
use Catmandu;
use namespace::clean;

has file_name => (is => 'ro', required => 1);
has fixer => (is => 'lazy');

sub _build_fixer {
    my $self = shift;
    my $fixer = Catmandu->fixer($self->file_name);
    return $fixer;
}

1;
