package Datahub::Factory;

our $VERSION = '0.01';

use Datahub::Factory::Sane;

use Datahub::Factory::Env;
use namespace::clean;
use Sub::Exporter::Util qw(curry_method);
use Sub::Exporter -setup => {
    exports => [
        log              => curry_method,
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

1;
__END__

=encoding utf-8


=head1 NAME

Datahub::Factory - A conveyor belt which transports data from a data source to
a Datahub instance.

=head1 SYNOPSIS

dhconveyor [ARGUMENTS] [OPTIONS]

=head1 DESCRIPTION

Datahub::Factory is a command line conveyor belt which automates three tasks:

=over

=item Data is fetched automatically from a local or remote data source.
=item Data is converted to an exchange format.
=item The output is pushed to an operational Datahub instance.

= back

Internally, Datahub::Factory uses Catmandu modules to transform the data, and
implements the Datahub REST API. Datahub::Factory stitches the transformation
and push tasks seamlessly together.

Datahub::Factory contains Log4perl support to monitor conveyor belt operations.

Note: This toolset is not a generic tool. It has been tailored towards the
functional requirements of the Flemish Art Collection use case.

=head1 COMMANDS

=head2 help COMMAND

Documentation about command line options.

=head2 transport [OPTIONS]

Fetch data from a local or remote source, convert it to an exchange format and
push the data to a Datahub instance.

--importer NAME
   The importer which fetches data from a Collection Registration system.
   Currently only "Adlib" and "TMS" are supported options.

--fixes PATH
  The path to the Catmandu Fix files to transform the data.

--oimport file_name=PATH
  The path to a flat file containing data. This option is only relevant when
  the input is an Adlib XML export file.

--oimport db_user=VALUE
  The database user. This option is only relevant when
  the input is an TMS database.

--oimport db_passowrd=VALUE
  The database user password. This option is only relevant when
  the input is an TMS database.

--oimport db_name=VALUE
  The database name. This option is only relevant when
  the input is an TMS database.

--oimport db_host=VALUE
  The database host. This option is only relevant when
  the input is an TMS database.

--ostore datahub_url=VALUE
  The URL to the datahub instance. This should be a FQDN ie. http://datahub.lan/

--ostore oauth_client_id=VALUE
  The client public ID. Used for OAuth authentication of the Datahub endpoint.

--ostore oauth_client_secret=VALUE
  The client secret passphrase. Used for OAuth authentication of the Datahub
  endpoint.

--ostore oauth_username=VALUE
  The username of the Datahub user. Used for OAuth authentication of the Datahub
  endpoint.

--ostore oauth_password=VALUE
  The password of the Datahub user. Used for OAuth authentication of the Datahub
  endpoint.

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
