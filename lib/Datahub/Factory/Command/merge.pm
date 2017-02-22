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

   my $catmandu_output;
    if (! defined($opt->{oexport}) || ! %{$opt->{oexport}}) {
        $catmandu_output = $export_module->new();
    } else {
        $catmandu_output = $export_module->new($opt->{oexport});
    }

    $left_input->importer->each(sub {
        my $left_item = shift;
        if (!$right_input->importer->can('get')) {
            $self->usage_error('Error: Can\'t do a lookup with the right importer. Use a Catmandu::Store, not a Catmandu::Importer!');
        }
        my $left_item_id = data_at($opt->{'ofixer'}->{'left_id_path'}, $left_item);
        my $right_item = $right_input->importer->get($left_item_id);
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
    });
}

1;
__END__