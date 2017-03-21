package Datahub::Factory;

our $VERSION = '0.7';

use Datahub::Factory::Sane;

use Datahub::Factory::Env;
use Datahub::Factory::Config;
use namespace::clean;
use Sub::Exporter::Util qw(curry_method);
use Sub::Exporter -setup => {
    exports => [
        log              => curry_method,
        cfg              => curry_method,
        importer         => curry_method
        fixer            => curry_method
        store            => curry_method
    ],
    collectors => {'-load' => \'_import_load', ':load' => \'_import_load',},
};

sub _import_load {
    my ($self, $value, $data) = @_;

    if (is_array_ref $value) {
      self->load(@$value);
    }
    else {
      $self->load;
    }

    1;
}

sub load {
    my $class = shift;
    my $env   = Datahub::Factory::Env->new();
    $class->_env($env);
    $class;
}

sub _env {
    my ($class, $env) = @_;
    state $loaded_env;
    $loaded_env = $env if defined $env;
    $loaded_env
        ||= Datahub::Factory::Env->new();
}

sub store {
    my $class = shift;
    $class->_env->store(@_);
}

sub importer {
    my $class = shift;
    $class->_env->importer(@_);
}

sub fixer {
    my $class = shift;
    $class->_env->fixer(@_);
}

sub log {
	$_[0]->_env->log;
}

sub cfg {
    my $cfg = Datahub::Factory::Config->new();
    return $cfg->config;
}

1;
__END__

=encoding utf-8


=head1 NAME

[![Build Status](https://travis-ci.org/thedatahub/Datahub-Factory.svg?branch=master)](https://travis-ci.org/thedatahub/Datahub-Factory)

Datahub::Factory - A conveyor belt which transports data from a data source to
a data sink.

=head1 SYNOPSIS

dhconveyor [ARGUMENTS] [OPTIONS]

=head1 DESCRIPTION

Datahub::Factory is a command line conveyor belt which automates three tasks:

=over

=item Data is fetched automatically from a local or remote data source.

=item Data is converted to an exchange format.

=item The output is pushed to a data sink.

=back

Datahub::Factory fetches data from several sources as specified by the
I<Importer> settings, executes a L<Fix|Catmandu::Fix> and sends it to
a data sink, set by I<Exporter>. Several importer and exporter modules
are supported.

Datahub::Factory contains Log4perl support to monitor conveyor belt operations.

Note: This toolset is not a generic tool. It has been tailored towards the
functional requirements of the Flemish Art Collection use case.

=head1 CONFIGURATION

Datahub::Factory uses a general configuration file called I<settings.ini>. It
can be located at C</etc/datahub-factory/settings.ini> or C<conf/settings.ini>.
The one in C</etc> takes priority. An example file is provided at
L<conf/settings.example.ini|https://github.com/thedatahub/Datahub-Factory/blob/master/conf/settings.example.ini>. It is in L<INI format|http://search.cpan.org/~sherzodr/Config-Simple-4.59/Simple.pm#INI-FILE>.

It has two parts, a C<[General]> block that contains some generic options, and
(optionally) multiple module-specific blocks called C<[module_Module_name]>.
For a list of module options, see the documentation for every module.

Supported modules

=over

=item L<PIDS|Datahub::Factory::Importer::PIDS>

=back

=head2 General options

=over

=item C<log_level>

Set the log_level. Takes a numeric parameter. Supported levels are:
1 (WARN), 2 (INFO), 3 (DEBUG). WARN (1) is the default.

=back

=head2 Example

    [General]
    # 1 => WARN; 2 => INFO; 3 => DEBUG
    log_level = 1

    [module_PIDS]
    username = username
    api_key = api_key

=head1 COMMANDS

=head2 help COMMAND

Documentation about command line options.

It is possible to provide either all importer and/or exporter options on the
command line, or to create a I<pipeline configuration file> that sets those
options.

=head2 transport [OPTIONS]

Fetch data from a local or remote source, convert it to an exchange format and
export the data.

L<Datahub::Factory::Command::transport>

=head2 merge [OPTIONS] (experimental)

Fetch data from two sources, convert it to an exchange format, merge the
two records and export the data.

L<Datahub::Factory::Command::merge>

=head1 AUTHORS

=over

=item Pieter De Praetere <pieter@packed.be>

=item Matthias Vandermaesen <matthias.vandermaesen@vlaamsekunstcollectie.be>

=back

=head1 COPYRIGHT

Copyright 2016 - PACKED vzw, Vlaamse Kunstcollectie vzw

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GPLv3.

=cut
