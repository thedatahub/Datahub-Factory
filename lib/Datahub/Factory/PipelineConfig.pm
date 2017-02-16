package Datahub::Factory::PipelineConfig;

use strict;
use warnings;

use Moo;
use namespace::clean;
use Config::Simple;

has conf_object => (is => 'ro', required => 1);

has opt => (is => 'lazy');

sub _build_opt {
    my $self = shift;
	if ( ! $self->conf_object->{pipeline} ) {
		return $self->from_cli_args();
	} else {
		return $self->parse_conf_file();
	}
}

sub parse_conf_file {
	my $self = shift;
	my $cfg = new Config::Simple($self->conf_object->{pipeline});
	my $opt = {
		'importer' => $cfg->param('Importer.plugin'),
		'exporter' => $cfg->param('Exporter.plugin'),
		'fixes' => $cfg->param('plugin_fixer_Fix.fix_file'),
		'id_path' => $cfg->param('Fixer.id_path'),
		'oimport' => $cfg->get_block(sprintf('plugin_importer_%s', $cfg->param('Importer.plugin'))),
		'oexport' => $cfg->get_block(sprintf('plugin_exporter_%s', $cfg->param('Exporter.plugin')))
	};
	return $opt;
}

sub from_cli_args {
	my $self = shift;
	# Why make things harder?
	return $self->conf_object;
}

sub check_object {
    my $self = shift;
    if ( ! $self->conf_object->{pipeline} ) {
		# Only require the CLI switches if no pipeline file was specified
		if ( ! $self->conf_object->{importer} ) {
			return "Importer is missing";
		}

		if ( ! $self->conf_object->{exporter} ) {
			return "Exporter is missing";
		}

		if ( ! $self->conf_object->{fixes} ) {
			return "Fixes are missing";
		}

		if ( $self->conf_object->{importer} eq "Adlib" ) {
			if ( ! $self->conf_object->{oimport}->{file_name} ) {
				return "Adlib: Import file is missing";
			}
		}

		if ( $self->conf_object->{importer} eq "TMS" ) {
			if ( ! $self->conf_object->{oimport}->{db_name} ) {
				return "TMS: database name is missing";
			}

			if ( ! $self->conf_object->{oimport}->{db_user} ) {
				return "TMS: database user is missing";
			}

			if ( ! $self->conf_object->{oimport}->{db_password} ) {
				return "TMS: database user password is missing";
			}

			if ( ! $self->conf_object->{oimport}->{db_host} ) {
				return "TMS: database host is missing";
			}
		}

		if ( $self->conf_object->{exporter} eq "Datahub" ) {
			# This should move to a separate module
			if ( ! $self->conf_object->{oexport}->{datahub_url} ) {
				return "Datahub: the URL to the datahub instance is missing";
			}

			if ( ! $self->conf_object->{oexport}->{oauth_client_id} ) {
				return "Datahub OAUTH: the client id is missing";
			}

			if ( ! $self->conf_object->{oexport}->{oauth_client_secret} ) {
				return "Datahub OAUTH: the client secret is missing";
			}

			if ( ! $self->conf_object->{oexport}->{oauth_username} ) {
				return "Datahub OAUTH: the client username is missing";
			}

			if ( ! $self->conf_object->{oexport}->{oauth_password} ) {
				return "Datahub OAUTH: the client passowrd is missing";
			}
		}
	} else {
		if ( ! -f $self->conf_object->{pipeline} ) {
			return sprintf('The configuration file %s does not exist', $self->conf_object->{pipeline});
		}
	}
    return undef;
}

1;