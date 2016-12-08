package Adlib::Import;

use Moo;
use Catmandu;
use strict;

has file_name => (is => 'ro', required => 1);
has data_path => (is => 'ro', default => sub { return 'recordList.record.*'; });

has importer  => (is => 'lazy');

sub _build_importer {
    my $self = shift;
    my $importer = Catmandu->importer('XML', file => $self->file_name, data_path => $self->data_path);
    return $importer;
}

1;