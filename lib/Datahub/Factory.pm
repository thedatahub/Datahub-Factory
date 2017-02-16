package Datahub::Factory;

our $VERSION = '0.02';

use Datahub::Factory::Sane;

use Datahub::Factory::Env;
use Datahub::Factory::Config;
use namespace::clean;
use Sub::Exporter::Util qw(curry_method);
use Sub::Exporter -setup => {
    exports => [
        log              => curry_method,
        cfg              => curry_method,
    ],
    collectors => {'-load' => \'_import_load', ':load' => \'_import_load',},
};

sub _import_load {
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
push the data to a Datahub instance.

=head3 Command line options

=over

=item C<--importer NAME>

The importer which fetches data from a Collection Registration system.
Currently only "Adlib" and "TMS" are supported options.
All C<--oimport> arguments are tied to the specific importer used.

=item C<--fixes PATH>

The path to the Catmandu Fix files to transform the data.

=item C<--exporter NAME>

The exporter that will do something with your data. It is possible to
print to C<STDOUT> in a specific format ("YAML" and "LIDO" are supported)
or to export to a Datahub instance.
All C<--oexport> arguments are tied to the specific exporter used.

=item C<--oimport file_name=PATH>

The path to a flat file containing data. This option is only relevant when
the input is an Adlib XML export file.

=item C<--oimport db_user=VALUE>

The database user. This option is only relevant when
the input is an TMS database.

=item C<--oimport db_passowrd=VALUE>

The database user password. This option is only relevant when
the input is an TMS database.

=item C<--oimport db_name=VALUE>

The database name. This option is only relevant when
the input is an TMS database.

=item C<--oimport db_host=VALUE>

The database host. This option is only relevant when
the input is an TMS database.

=item C<--oexport datahub_url=VALUE>

The URL to the datahub instance. This should be a FQDN ie. http://datahub.lan/

=item C<--oexport oauth_client_id=VALUE>

The client public ID. Used for OAuth authentication of the Datahub endpoint.

=item C<--oexport oauth_client_secret=VALUE>

The client secret passphrase. Used for OAuth authentication of the Datahub
endpoint.

=item C<--oexport oauth_username=VALUE>

The username of the Datahub user. Used for OAuth authentication of the Datahub
endpoint.

=item C<--oexport oauth_password=VALUE>

The password of the Datahub user. Used for OAuth authentication of the Datahub
endpoint.

=back

=head3 Pipeline configuration file

The I<pipeline configuration file> is in the L<INI format|http://search.cpan.org/~sherzodr/Config-Simple-4.59/Simple.pm#INI-FILE> and its location is
provided to the application using the C<--pipeline> switch.

The file is broadly divided in two parts: the first (shortest) part configures
the pipeline itself and sets the plugins to use for the I<import>, I<fix> and
I<export> actions. The second part sets options specific for the used plugins.

=head4 Pipeline configuration

This part has three sections: C<[Importer]>, C<[Fixer]> and C<[Exporter]>.
Every section has just one option: C<plugin>. Set this to the plugin you
want to use for every action.

All current supported plugins are in the C<Importer> and C<Exporter> folders.
For the C<[Fixer]>, only the I<Fix> plugin is supported.

The C<[Fixer]> has an additional option, C<id_path>. This options contains the
path (in Fix syntax) of the identifier of each record in your data after the
fix has been applied, but before it is submitted to the I<Exporter>. It is used
for reporting and logging.

Supported I<Importer> plugins:

=over

=item L<TMS|Datahub::Factory::Importer::TMS>

=item L<Adlib|Datahub::Factory::Importer::Adlib>

=item L<KMSKA|Datahub::Factory::Importer::KMSKA>

=item L<MSK|Datahub::Factory::Importer::MSK>

=item L<VKC|Datahub::Factory::Importer::VKC>

=back

Supported I<Exporter> plugins:

=over

=item L<Datahub|Datahub::Factory::Exporter::Datahub>

=item L<LIDO|Datahub::Factory::Exporter::LIDO>

=item L<YAML|Datahub::Factory::Exporter::YAML>

=back

=head4 Plugin configuration

All plugins have their own configuration options in sections called
C<[plugin_type_name]> where C<type> can be I<importer>, I<exporter>
or I<fixer> and C<name> is the name of the plugin (see above).

For a list of supported and required options, see the plugin documentation.

=head4 Example configuration file

  [Importer]
  plugin = Adlib

  [Fixer]
  plugin = Fix
  id_path = 'administrativeMetadata.recordWrap.recordID.0._'

  [Exporter]
  plugin = Datahub

  [plugin_importer_Adlib]
  file_name = '/tmp/adlib.xml'
  data_path = 'recordList.record.*'

  [plugin_fixer_Fix]
  fix_file = '/tmp/msk.fix'

  [plugin_exporter_Datahub]
  datahub_url = my.thedatahub.io
  datahub_format = LIDO
  oauth_client_id = datahub
  oauth_client_secret = datahub
  oauth_username = datahub
  oauth_password = datahub

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
