package Datahub::Factory::Command::merge;

use Datahub::Factory::Sane;

use parent 'Datahub::Factory::Cmd';

use Module::Load;
use Catmandu;
use Catmandu::Util qw(data_at);
use Datahub::Factory;
use namespace::clean;
use Datahub::Factory::PipelineConfig;
use Datahub::Factory::Fixer::Merge;

use Data::Dumper qw(Dumper);

sub abstract { "Merge data from two sources and push it to a single exporter" }

sub description { "Long description on blortex algorithm" }

sub opt_spec {
	return (
		[ "pipeline|i:s", "Location of the pipeline configuration file"],
	);
}

sub validate_args {
	my ($self, $opt, $args) = @_;

	my $pc = Datahub::Factory::PipelineConfig->new(conf_object => $opt);
	if (defined($pc->check_object())) {
		$self->usage_error($pc->check_object())
	}
	

	# no args allowed but options!
	$self->usage_error("No args allowed") if @$args;
}

sub execute {
    my ($self, $arguments, $args) = @_;

    my $pcfg = Datahub::Factory::PipelineConfig->new(conf_object => $arguments);

    my $opt = $pcfg->opt;

    my $logger = Datahub::Factory->log;
    my $cfg = Datahub::Factory->cfg;

    if ($opt->{'fixer'} ne 'Merge') {
        $self->usage_error('Only the "Merge" Fixer module is supported. ')
    }

    # Load modules
    my $export_module = sprintf("Datahub::Factory::Exporter::%s", $opt->{exporter});;
    autoload $export_module;

    my $fix_module = 'Datahub::Factory::Fixer';
    autoload $fix_module;

    my $left_record_import_module = sprintf('Datahub::Factory::Importer::%s', $opt->{'ofixer'}->{'left_record_plugin'});
    autoload $left_record_import_module;
    my $right_record_import_module = sprintf('Datahub::Factory::Importer::%s', $opt->{'ofixer'}->{'right_record_plugin'});
    autoload $right_record_import_module;

    # Perform import/fix/export
    my $left_input;
    my $right_input;
    if (! defined($opt->{'o_left_importer'}) || ! %{$opt->{'o_left_importer'}}) {
        $left_input = $left_record_import_module->new();
    } else {
        $left_input = $left_record_import_module->new($opt->{'o_left_importer'});
    }
    if (! defined($opt->{'o_right_importer'}) || ! %{$opt->{'o_right_importer'}}) {
        $right_input = $right_record_import_module->new();
    } else {
        $right_input = $right_record_import_module->new($opt->{'o_right_importer'});
    }
    my $left_fixer = $fix_module->new("file_name" => $opt->{'ofixer'}->{'left_fix_file_name'});
    my $right_fixer = $fix_module->new("file_name" => $opt->{'ofixer'}->{'right_fix_file_name'});

   my $catmandu_output;
    if (! defined($opt->{oexport}) || ! %{$opt->{oexport}}) {
        $catmandu_output = $export_module->new();
    } else {
        $catmandu_output = $export_module->new($opt->{oexport});
    }

    $left_input->importer->each(sub {
        my $left_item = shift;
        my $fixed_item = $left_fixer->fixer->fix($left_item);
        if (!$right_input->importer->can('get')) {
            $self->usage_error('Error: Can\'t do a lookup with the right importer. Use a Catmandu::Store, not a Catmandu::Importer!');
        }
        my $left_item_id = data_at($opt->{'ofixer'}->{'left_id_path'}, $left_item);
        if (!defined($left_item_id)) {
            $logger->error(sprintf('Error: ID of the left item is undefined.'));
            return;
        }
        my $right_item = $right_input->importer->get($left_item_id);
        $right_item = $right_fixer->fixer->fix($right_item);
        my $m = Datahub::Factory::Fixer::Merge->new(
            left_record => $left_item,
            right_record => $right_item
        );
        my $merged = $m->merged_record;
        try {
            $catmandu_output->out->add($merged);
        } catch {
            my $msg;
            if ($_->can('message')) {
                $msg = sprintf("Error while adding item %s: %s", $left_item_id, $_->message);
            } else {
                $msg = sprintf("Error while adding item %s: %s", $left_item_id, $_);
            }
            $logger->error($msg);
            $logger->error(sprintf("Item: ", $merged));
        } finally {
            if (!@_) {
                $logger->info(sprintf("Added item %s.", $left_item_id));
            }
    };
    exit(0);
    });
}

1;
__END__

=head1 NAME

Datahub::Factory::Command::merge - Implements the 'merge' command.

=head1 DESCRIPTION
This command allows datamanagers to (a) fetch data from a two sources (b)
transform the data to LIDO using a fix (c) merge the two records
and (d) upload the LIDO transformed data to a Datahub instance.

=head1 COMMAND LINE INTERFACE

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
For the C<merge> command, you must set the C<[Fixer]> plugin to C<Merge>.
The C<[Importer]> settings are ignored.

In C<[plugin_fixer_Merge]>, two records are merged: a left record and a
right record. The right record takes precedence.

You must set the following options:

=over

=item C<left_record_plugin>

I<Importer> plugin to use to get the left record. Can be a L<Catmandu::Store>
or a L<Catmandu::Importer>. Configuration options for the plugin are set in
C<[plugin_importer_PLUGIN_NAME]> (see below).

=item C<left_id_path>

Path of the ID (in Fix language) in the left record after the fixes have been
applied. The ID is used to look up the right record.

=item C<left_fix_file_name>

Fixes to apply to the left record.

=item C<right_record_plugin>

I<Importer> plugin to use to get the right record. Can only be a
L<Catmandu::Store>.

=item C<right_fix_file_name>

Fixes to apply to the right record.

=back

Supported I<Importer> plugins:

=over

=item L<TMS|Datahub::Factory::Importer::TMS>

=item L<Adlib|Datahub::Factory::Importer::Adlib>

=item L<KMSKA|Datahub::Factory::Importer::KMSKA>

=item L<MSK|Datahub::Factory::Importer::MSK>

=item L<VKC|Datahub::Factory::Importer::VKC>

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

=head4 Example configuration file

    [Fixer]
    plugin = Merge

    [Exporter]
    plugin = YAML
    [plugin_importer_MSK]
    file_name = '/vagrant/Datahub-Fixes/msk_test.xml'
    data_path = 'recordList.record.*'

    [plugin_importer_CollectiveAccess]
    endpoint = 'http://demo.collectiveaccess.com'
    username = 'demo'
    password = 'demo'

    [plugin_fixer_Merge]
    left_record_plugin = MSK
    left_id_path = 'lidoRecID.0._'
    left_fix_file_name = '/vagrant/Datahub-Fixes/msk.fix'

    right_record_plugin = CollectiveAccess
    right_fix_file_name = '/vagrant/Datahub-Factory/ca.fix'

    [plugin_exporter_YAML]

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
