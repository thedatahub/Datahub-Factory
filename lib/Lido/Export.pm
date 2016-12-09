package Lido::Export;

use Moo;
use Catmandu;
use strict;

has file_name => (is => 'ro', required => 1);

has out  => (is => 'lazy');

sub _build_out {
    my $self = shift;
    my $exporter = Catmandu->exporter('LIDO');
    return $exporter;
}

1;