package Datahub::Factory::Pipeline;

use strict;
use warnings;

use Moo;
use namespace::clean;
use Config::Simple;
use Data::Dumper qw(Dumper);

has file_name    => (is => 'ro', required => 1);
has config       => (is => 'lazy');

sub _build_config {
    my $self = shift;
    return new Config::Simple($self->file_name);
}

sub parse {
    my $self = shift;
    my $options;

    # Collect all plugins
    my $importer_plugin = $self->config->param('Importer.plugin');
    if (!defined($importer_plugin)) {
        die 'Undefined value for plugin at [Importer]';
    }
    $options->{sprintf('importer_%s', $importer_plugin)} = $self->plugin_options('importer', $importer_plugin);

    my $fixer_plugin = $self->config->param('Fixer.plugin');
    if (!defined($fixer_plugin)) {
        die 'Undefined value for plugin at [Fixer]';
    }
    $options->{sprintf('fixer_%s', $fixer_plugin)} = $self->plugin_options('fixer', $fixer_plugin);

    foreach my $fixer_conditional_plugin (@{$options->{sprintf('fixer_%s', $fixer_plugin)}->{'fixers'}}) {
        $options->{sprintf('fixer_%s', $fixer_conditional_plugin)} = $self->block_options(sprintf('plugin_fixer_%s', $fixer_conditional_plugin));
    }

    my $exporter_plugin = $self->config->param('Exporter.plugin');
    if (!defined($exporter_plugin)) {
        die 'Undefined value for plugin at [Exporter]';
    }
    $options->{sprintf('exporter_%s', $exporter_plugin)} = $self->plugin_options('exporter', $exporter_plugin);

    $options->{'importer'} = $self->config->param('Importer.plugin');
    $options->{'fixer'} = $self->config->param('Fixer.plugin');
    $options->{'exporter'} = $self->config->param('Exporter.plugin');

    if (!defined($self->config->param('Importer.id_path'))) {
        die "Missing required property id_path in the [Importer] block.";
    }
    $options->{'id_path'} = $self->config->param('Importer.id_path');

    # Legacy options
    $options->{'oimport'} = $options->{sprintf('importer_%s', $options->{'importer'})};
    $options->{'oexport'} = $options->{sprintf('exporter_%s', $options->{'exporter'})};

    return $options;
}

sub plugin_options {
    my ($self, $plugin_type, $plugin_name) = @_;
    return $self->block_options(sprintf('plugin_%s_%s', $plugin_type, $plugin_name));
}

sub module_options {
    my ($self, $module_name) = @_;
    return $self->block_options(sprintf('module_%s', $module_name));
}

sub block_options {
    my ($self, $plugin_block_name) = @_;
    return $self->config->get_block($plugin_block_name);
}

1;

__END__

