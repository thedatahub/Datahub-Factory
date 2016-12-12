package Lido::Export;

use Moo;
use Catmandu;
use strict;

has file_name => (is => 'ro');

has out  => (is => 'lazy');

sub _build_out {
    my $self = shift;
    my $exporter;
    if (defined($self->file_name)) {
        $exporter = Catmandu->exporter('LIDO', file => $self->file_name);
    } else {
        $exporter = Catmandu->exporter('LIDO');
    }
    return $exporter;
}

1;