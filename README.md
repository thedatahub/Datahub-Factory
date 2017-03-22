# NAME

<div>
    <a href="https://travis-ci.org/thedatahub/Datahub-Factory"><img src="https://travis-ci.org/thedatahub/Datahub-Factory.svg?branch=master"></a>
</div>

Datahub::Factory - A conveyor belt which transports data from a data source to
a data sink.

# SYNOPSIS

dhconveyor \[ARGUMENTS\] \[OPTIONS\]

# DESCRIPTION

Datahub::Factory is a command line conveyor belt which automates three tasks:

- Data is fetched automatically from a local or remote data source.
- Data is converted to an exchange format.
- The output is pushed to a data sink.

Datahub::Factory fetches data from several sources as specified by the
_Importer_ settings, executes a [Fix](https://metacpan.org/pod/Catmandu::Fix) and sends it to
a data sink, set by _Exporter_. Several importer and exporter modules
are supported.

Datahub::Factory contains Log4perl support to monitor conveyor belt operations.

Note: This toolset is not a generic tool. It has been tailored towards the
functional requirements of the Flemish Art Collection use case.

# CONFIGURATION

Datahub::Factory uses a general configuration file called _settings.ini_. It
can be located at `/etc/datahub-factory/settings.ini` or `conf/settings.ini`.
The one in `/etc` takes priority. An example file is provided at
[conf/settings.example.ini](https://github.com/thedatahub/Datahub-Factory/blob/master/conf/settings.example.ini). It is in [INI format](http://search.cpan.org/~sherzodr/Config-Simple-4.59/Simple.pm#INI-FILE).

It has two parts, a `[General]` block that contains some generic options, and
(optionally) multiple module-specific blocks called `[module_Module_name]`.
For a list of module options, see the documentation for every module.

Supported modules

- [PIDS](https://metacpan.org/pod/Datahub::Factory::Importer::PIDS)

## General options

- `log_level`

    Set the log\_level. Takes a numeric parameter. Supported levels are:
    1 (WARN), 2 (INFO), 3 (DEBUG). WARN (1) is the default.

## Example

    [General]
    # 1 => WARN; 2 => INFO; 3 => DEBUG
    log_level = 1

    [module_PIDS]
    username = username
    api_key = api_key

# COMMANDS

## help COMMAND

Documentation about command line options.

It is possible to provide either all importer and/or exporter options on the
command line, or to create a _pipeline configuration file_ that sets those
options.

## transport \[OPTIONS\]

Fetch data from a local or remote source, convert it to an exchange format and
export the data.

[Datahub::Factory::Command::transport](https://metacpan.org/pod/Datahub::Factory::Command::transport)

# AUTHORS

- Pieter De Praetere <pieter@packed.be>
- Matthias Vandermaesen <matthias.vandermaesen@vlaamsekunstcollectie.be>

# COPYRIGHT

Copyright 2016 - PACKED vzw, Vlaamse Kunstcollectie vzw

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GPLv3.
