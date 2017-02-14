package Datahub::Factory::Importer::MSK;

use strict;
use warnings;

use Moo;
use Catmandu;

use Config::Simple;

use Datahub::Factory::Importer::Adlib;
use Datahub::Factory::Importer::PIDS;

with 'Datahub::Factory::Importer';

has file_name => (is => 'ro', required => 1);
has data_path => (is => 'ro', default => sub { return 'recordList.record.*'; });

has adlib    => (is => 'lazy');
has pids     => (is => 'lazy');

sub _build_importer {
    my $self = shift;
    my $importer = $self->adlib->importer;
    $self->prepare();
    return $importer;
}

sub _build_adlib {
    my $self = shift;
    my $adlib = Datahub::Factory::Importer::Adlib->new(
        file_name => $self->file_name,
        data_path => $self->data_path
    );
    return $adlib;
}

sub _build_pids {
    my $self = shift;
    return Datahub::Factory::Importer::PIDS->new(
        username => $self->config->param('PIDS.username'),
        api_key  => $self->config->param('PIDS.api_key')
    );
}

sub prepare {
    my $self = shift;
    $self->logger->info('Creating "pids" temporary table.');
    $self->__pids();
    $self->logger->info('Creating "creators" temporary table.');
    $self->__creators();
    $self->logger->info('Creating "aat" temporary table.');
    $self->__aat();
}

sub __pids {
    my $self = shift;
    $self->pids->temporary_table($self->pids->get_object('PIDS_MSK_UTF8.csv'));
}

sub __creators {
    my $self = shift;
    $self->pids->temporary_table($self->pids->get_object('CREATORS_MSK_UTF8.csv'));
}

sub __aat {
    my $self = shift;
    $self->pids->temporary_table($self->pids->get_object('AAT_UTF8.csv'), 'record - object_name');
}

1;