package Datahub::Factory::Fix;

use Moo;
use Catmandu;
use strict;

has file_name => (is => 'ro', required => 1);

has fixer => (is => 'lazy');

sub _build_fixer {
    my $self = shift;
    my $fixer = Catmandu->fixer($self->file_name);
    return $fixer;
}

1;