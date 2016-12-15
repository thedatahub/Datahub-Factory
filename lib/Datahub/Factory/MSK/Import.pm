package Datahub::Factory::MSK::Import;

use Moo;
use Catmandu;
use strict;

use Config::Simple;

use Datahub::Factory::Adlib::Import;
use Datahub::Factory::Import::PIDS;

has file_name => (is => 'ro', required => 1);
has data_path => (is => 'ro', default => sub { return 'recordList.record.*'; });

has importer => (is => 'lazy');
has adlib    => (is => 'lazy');
has pids     => (is => 'lazy');
has config   => (is => 'lazy');
has logger   => (is => 'lazy');

sub _build_importer {
    my $self = shift;
    my $importer = $self->adlib->importer;
    $self->prepare();
    return $importer;
}

sub _build_adlib {
    my $self = shift;
    my $adlib = Datahub::Factory::Adlib::Import->new(
        file_name => $self->file_name,
        data_path => $self->data_path
    );
    return $adlib;
}

sub _build_pids {
    my $self = shift;
    return Datahub::Factory::Import::PIDS->new(
        username => $self->config->param('PIDS.username'),
        api_key  => $self->config->param('PIDS.api_key')
    );
}

sub _build_config {
    my $self = shift;
    return new Config::Simple('conf/settings.ini');
}

sub _build_logger {
    my $self = shift;
    return Log::Log4perl->get_logger('datahub');
}

sub prepare {
    my $self = shift;
    $self->__pids();
    $self->__creators();
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