package Datahub::Factory::Command::redistransport;

use Datahub::Factory::Sane;

use parent 'Datahub::Factory::Cmd';

use Module::Load;
use Catmandu;
use Catmandu::Util qw(data_at);
use Datahub::Factory;
use namespace::clean;
use Datahub::Factory::PipelineConfig;
use Datahub::Factory::Redis::Jobs;
use Datahub::Factory::Redis::Queue;
use Redis::JobQueue::Job qw(
    STATUS_CREATED
    STATUS_WORKING
    STATUS_COMPLETED
    STATUS_FAILED
);

use Data::Dumper qw(Dumper);

sub abstract { "Transport data from a data source to a datahub instance" }

sub description { "Long description on blortex algorithm" }

sub opt_spec {
	return (
		[ "pipeline|p=s", "Location of the pipeline configuration file"]
	);
}

sub validate_args {
	my ($self, $opt, $args) = @_;

    if (! $opt->{'pipeline'}) {
        $self->usage_error('The --pipeline flag is required.');
    }

	my $pcfg = Datahub::Factory->pipeline($opt);
    try {
        $pcfg->check_object();
    } catch {
        $self->usage_error($_);
    }
	# no args allowed but options!
	$self->usage_error("No args allowed") if @$args;
}

sub execute {
  my ($self, $arguments, $args) = @_;

  my $logger = Datahub::Factory->log;

  my ($pcfg, $opt);
  try {
      $pcfg = Datahub::Factory->pipeline($arguments);
      $opt = $pcfg->opt;
  } catch {
      $logger->fatal($_);
      exit 1;
  };

  # Load modules
  my ($import_module, $fix_module, $export_module);
  try {
      $import_module = Datahub::Factory->importer($opt->{importer})->new($opt->{oimport});
  } catch {
      $logger->fatal(sprintf('%s at [plugin_importer_%s]', $_, $opt->{'importer'}));
      exit 1;
  };

  # Perform import/fix/export

  # Catmandu::Fix treats all warnings as fatal errors (this is good)
  # so we can catch them with try-catch
  # Not that errors here are _not_ fatal => continue running
  # till all records have been processed
  my $counter = 0;
  my @fix_jobs;
  my $fix_jq = Datahub::Factory::Redis::Queue->new(queue_name => 'fixer');
  $import_module->importer->each(sub {
      my $item = shift;
      $counter++;
      #https://metacpan.org/pod/Redis::JobQueue
      # Add fixer job
      # exit importer
      # Loop to wait for finished job
      # Add to exporter via job
      # Loop to waint for finished job

      my $job = $item;
      #my ($module_name, $module_plugin, $module_options, $item, $counter, $item_id) = @{$job->workload};
      my $r_job = $fix_jq->add(['fixer', $opt->{'fixer'}, $opt->{'ofixer'}, $job, $counter]);

      push @fix_jobs, $r_job->{'id'};
  });

# TODO: throttling

  my $exp_jq = Datahub::Factory::Redis::Queue->new(queue_name => 'exporter');
  my @export_jobs;
  while (my $fix_job = shift @fix_jobs) {
      my $r_f_job = $fix_jq->get($fix_job);
      if ($r_f_job->{'status'} ne STATUS_COMPLETED && $r_f_job->{'status'} ne STATUS_FAILED) {
          push @fix_jobs, $fix_job;
      }
      if (ref ($r_f_job->{'result'}) ne ref({})) {
          $logger->error(${$r_f_job->{'result'}});
          next;
      }
      my $item = $r_f_job->{'result'};
      my $job = $item;
      my $item_id = data_at($opt->{'id_path'}, $item);

      #my ($module_name, $module_plugin, $module_options, $item, $counter, $item_id) = @{$job->workload};
      my $r_e_job = $exp_jq->add(['exporter', $opt->{'exporter'}, $opt->{'oexport'}, $job, $counter, $item_id]);

      push @export_jobs, $r_e_job->{'id'};
  }

  while (my $export_job = shift @export_jobs) {
      my $r_e_job = $exp_jq->get($export_job);
      if ($r_e_job->{'status'} ne STATUS_COMPLETED && $r_e_job->{'status'} ne STATUS_FAILED) {
          push @export_jobs, $export_job;
      }
      if (ref ($r_e_job->{'result'}) ne ref({})) {
          $logger->error(${$r_e_job->{'result'}});
          next;
      }
      my $item = $r_e_job->{'result'};
      my $item_id = data_at($opt->{'id_path'}, $item);
      $logger->info(sprintf('Item %s (id): exported.', $item_id));
  }

}

#

1;

__END__

=head1 NAME

Datahub::Factory::Command::transport - Implements the 'transport' command.

=head1 DESCRIPTION
This command allows datamanagers to (a) fetch data from a (local) source (b)
transform the data to LIDO using a fix (c) upload the LIDO transformed data to
a Datahub instance.

=head1 COMMAND LINE INTERFACE

=head2 Options

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

=head2 Pipeline configuration file

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

Supported I<Importer> plugins:

=over

=item L<TMS|Datahub::Factory::Importer::TMS>

=item L<Adlib|Datahub::Factory::Importer::Adlib>

=item L<OAI|Datahub::Factory::Importer::OAI>

=back

Supported I<Exporter> plugins:

=over

=item L<Datahub|Datahub::Factory::Exporter::Datahub>

=item L<LIDO|Datahub::Factory::Exporter::LIDO>

=item L<YAML|Datahub::Factory::Exporter::YAML>

=back

=head3 Plugin configuration

All plugins have their own configuration options in sections called
C<[plugin_type_name]> where C<type> can be I<importer>, I<exporter>
or I<fixer> and C<name> is the name of the plugin (see above).

For a list of supported and required options, see the plugin documentation.

The C<[plugin_fixer_Fix]> has two options: C<id_path> and C<file_name>.

The C<id_path> option contains the path (in Fix syntax) of the identifier of
each record in your data after the fix has been applied, but before it is
submitted to the I<Exporter>. It is used for reporting and logging.

C<file_name> points to the location of your Fix file.

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
  file_name = '/tmp/msk.fix'
  id_path = ''

  [plugin_exporter_Datahub]
  datahub_url = https://my.thedatahub.io
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
