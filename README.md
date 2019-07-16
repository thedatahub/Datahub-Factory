# NAME

Datahub::Factory - A CLI tool that transforms and transports data from a data source to a data sink.

# STATUS

[![Build Status](https://travis-ci.org/thedatahub/Datahub-Factory.svg?branch=master)](https://travis-ci.org/thedatahub/Datahub-Factory)
[![CPANTS kwalitee](https://cpants.cpanauthors.org/dist/Datahub-Factory.png)](https://cpants.cpanauthors.org/dist/Datahub-Factory)

# SYNOPSIS

    # From the command line
    $ dhconveyor <command> OPTIONS

    # Transport data via a pipeline configuration file, without output
    $ dhconveyor transport -p pipeline.ini

    # Pretty output
    $ dhconveyor transport -p pipeline.ini -v

    # Show logging output
    # Log levels: 1 - 3
    $ dhconveyor transport -p pipeline.ini -L 3

    # Only process the first 5 records
    $ dhconveyor transport -p pipeline.ini -n 5

    # Breaking up the pipeline configuration file in separate files
    $ dhconveyor transport -g general.ini -i importer.ini -f fixer.ini -e exporter.ini

    # Pushing a JSON file to a search index (Solr)
    $ dhconveyor index -p solr.ini

    # Pretty output
    $ dhconveyor index -p solr.ini -v

    # Show logging output
    # Log levels: 1 - 3
    $ dhconveyor index -p solr.ini -L 3

# DESCRIPTION

This package implements a command line ETL (Extract, Transform, Load) toolkit written as a wrapper around [Catmandu](https://metacpan.org/pod/Catmandu) and its ecosystem of Perl modules.

Features:

- Configuration files as ETL pipelines. The [Catmandu](https://metacpan.org/pod/Catmandu) command takes input via CLI options and arguments that are defined in its modules. Depending on the invocation, commands can end up with a long list of parameters containing potentially sensitive information. Sequestering that information in separate files allows users to approach pipelines as a configuration management concern.
- Conditional transforming. Pipelines can define multiple Catmandu Fixes. A check on a context dependent value (i.e. a repository field) allows the toolkit to dynamically apply the correct fix at runtime.
- Loose coupling with the Catmandu ecosystem. Wrapping Catmandu modules brings dependency inversion. This makes it easier to swap out Catmandu modules for something else without touching the infrastructure configuration.
- Robust processing with an increased fault-tolerance. Invalid records or input will simply be logged, rather then halting the entire process.
- Extensibility. Leveraging a modular approach, this toolkit can be expanded by custom modules for specific use cases.

[Datahub::Factory](https://metacpan.org/pod/Datahub::Factory) fetches data from several sources as specified by the Importer settings, executes a [Catmandu::Fix](https://metacpan.org/pod/Catmandu::Fix) and sends it to a data sink, set via an Exporter. Several importer and exporter modules are provided out of the box, but developers can extend the functionality with their own modules.

[Datahub::Factory](https://metacpan.org/pod/Datahub::Factory) supports [Log4perl](https://metacpan.org/pod/Log4perl).

# USE

## Command line options

All commands share the following switches:

- --log\_level --L \[int\]

    Set the log\_level. Takes a numeric parameter. Supported levels are: 1 (WARN), 
    2 (INFO), 3 (DEBUG). WARN (1) is the default.

- --log\_output

    Selects an output for the log messages. By default, it will send them to STDERR 
    (pass STDERR as parameter), but STDOUT (STDOUT) and a log file.

- --verbose -v

    Set verbosity. Invoking the command with the --verbose, -v flag will render 
    verbose output to the terminal.

- --number -n \[int\]

    Set number of records to process. Invoking the transport command with the --number, -n flag will process the first \[int\] records instead of all records available at the data source.

## Available Commands

### help COMMAND

Documentation about command line options.

### [transport OPTIONS](https://metacpan.org/pod/Datahub::Factory::Command::transport)

Fetch data from a local or remote source, convert the data to a target format and structure and export the data to a local or remote data sink.

### [index OPTIONS](https://metacpan.org/pod/Datahub::Factory::Command::index)

Fetch data from a local source, and push it to an enterprise search engine in bulk. Currently only supports Apache Solr ([https://lucene.apache.org/solr/](https://lucene.apache.org/solr/))

# CONFIGURATION

Pipelines are defined in configuration files which are formatted according to the INI structure as expected by the [Config::Simple](https://metacpan.org/pod/Config::Simple) library. Any pipeline consists of 4 parts: a General block, an Importer block, a Fixer block and an Exporter block.

Examples can be found in [https://github.com/thedatahub/Datahub-Factory-Pipelines](https://github.com/thedatahub/Datahub-Factory-Pipelines).

A simple example that pushes OAI data to a YAML output on STDOUT:

    [General]
    id_path = administrativeMetadata.recordWrap.recordID.0._

    [Importer]
    plugin = OAI

    [plugin_importer_OAI]
    endpoint =  https://datahub.vlaamsekunstcollectie.be/oai
    handler = +Catmandu::Importer::OAI::Parser::lido
    metadata_prefix = oai_lido

    [Fixer]
    plugin = Fix

    [plugin_fixer_Fix]
    file_name = '/home/foobar/datahub.fix'

    [Exporter]
    plugin = YAML

    [Exporter_YAML]

Note: The datahub.fix file is required, but can be left empty.

An example defining multiple fix transforms based on a context dependent value:

    [General]
    id_path = 'administrativeMetadata.recordWrap.recordID.0._'

    [Importer]
    plugin = OAI

    [plugin_importer_OAI]
    # endpoint = 'http://collections.britishart.yale.edu/oaicatmuseum/OAIHandler'
    endpoint = https://datahub.vlaamsekunstcollectie.be/oai
    handler = +Catmandu::Importer::OAI::Parser::lido
    metadata_prefix = oai_lido

    [Fixer]
    plugin = Fix

    [plugin_fixer_Fix]
    condition_path = '_metadata.administrativeMetadata.0.recordWrap.recordSource.0.legalBodyName.0.appellationValue.0._'
    fixers = MSK, GRO

    [plugin_fixer_GRO]
    condition = 'Musea Brugge - Groeningemuseum'
    file_name = '/Users/foobar/groeninge.fix'
    
    [plugin_fixer_MSK]
    condition = 'Museum voor Schone Kunsten Gent'
    file_name = '/Users/foobar/msk.fix'

    [Exporter]
    plugin = YAML

    [plugin_exporter_YAML]

Note: condition\_path contains the Fix path to the node that contains the context-dependent value. The condtion parameter in each fixer contains the value against which the conditional check is performed.

# API

Datahub::Factory leverages a plugin-based architecture. This makes extending the toolkit with new functionality fairly trivial.

New commands can be added by creating a new, separate Perl module that contains a \`command\_name.pm\` file in the \`lib/Datahub/Factory/Command\` path. 
Datahub::Factory uses the [Datahub::Factory::Command](https://metacpan.org/pod/Datahub::Factory::Command) namespace and leverages [App::Cmd](https://metacpan.org/pod/App::Cmd) internally.

New [Datahub::Factory::Importer](https://metacpan.org/pod/Datahub::Factory::Importer), [Datahub::Factory::Exporter](https://metacpan.org/pod/Datahub::Factory::Exporter), [Datahub::Factory::Fixer](https://metacpan.org/pod/Datahub::Factory::Fixer), [Datahub::Factory::Indexer](https://metacpan.org/pod/Datahub::Factory::Indexer) plugins can be added in the same way.

# AUTHORS

- Matthias Vandermaesen `matthias.vandermaesen@vlaamsekunstcollectie.be`
- Pieter De Praetere `pieter@packed.be`

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016, 2019 by PACKED, vzw, Vlaamse Kunstcollectie, vzw.

This is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License, Version 3, June 2007.
