package Datahub::Factory::Importer::PIDS;

use strict;
use warnings;

use Moo;
use Catmandu;

use WebService::Rackspace::CloudFiles;
use File::Basename;

has username       => (is => 'ro', required => 1);
has api_key        => (is => 'ro', required => 1);
has container_name => (is => 'ro', default => 'datahub');

has client    => (is => 'lazy');
has container => (is => 'lazy');

sub _build_client {
    my $self = shift;
    return WebService::Rackspace::CloudFiles->new(
        user => $self->username,
        key  => $self->api_key
    );
}

sub _build_container {
    my $self = shift;
    return $self->client->container(name => $self->container_name);
}

sub get_object {
    my ($self, $object_name) = @_;
    my $object = $self->container->object(name => $object_name);
    my $file_name = $object_name;
    $file_name =~ s/[^A-Za-z0-9\-\.]/./g;
    $object->get_filename(sprintf('/tmp/%s', $file_name));
    return sprintf('/tmp/%s', $file_name);
}

sub temporary_table {
    my ($self, $csv_location, $id_column) = @_;
    my $store_table = fileparse($csv_location, '.csv');

    my $importer = Catmandu->importer(
        'CSV',
        file => $csv_location
    );
    my $store = Catmandu->store(
        'DBI',
        data_source => sprintf('dbi:SQLite:/tmp/import.%s.sqlite', $store_table),
    );
    $importer->each(sub {
            my $item = shift;
            if (defined ($id_column)) {
                $item->{'_id'} = $item->{$id_column};
            }
            my $bag = $store->bag();
            # first $bag->get($item->{'_id'})
            $bag->add($item);
        });
}

1;