package Datahub::Factory::Command::transport;

use Datahub::Factory::Sane;

use parent 'Datahub::Factory::Cmd';

use Module::Load;
use Catmandu;
use Datahub::Factory;
use namespace::clean;
use Datahub::Factory::PipelineConfig;

use Data::Dumper qw(Dumper);

sub abstract { "Transport data from a data source to a datahub instance" }

sub description { "Long description on blortex algorithm" }

sub opt_spec {
	return (
		[ "pipeline|i:s", "Location of the pipeline configuration file"],
		[ "importer|i:s",  "The importer" ],
		[ "datahub|d:s",  "The datahub instance" ],
		[ "exporter|e:s",  "The exporter"],
		[ "fixes|f:s",  "Fixes"],
		[ "oimport|oi:s%",  "import options"],
		[ "oexport|oe:s%",  "export options"],
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

  my $cfg = Datahub::Factory::PipelineConfig->new(conf_object => $arguments);

  my $opt = $cfg->opt;

  my $logger = Datahub::Factory->log;

  # Load modules
  my $export_module = sprintf("Datahub::Factory::Exporter::%s", $opt->{exporter});;
  autoload $export_module;

  my $fix_module = 'Datahub::Factory::Fixer';
  autoload $fix_module;

  my $import_module = sprintf("Datahub::Factory::Importer::%s", $opt->{importer});
  autoload $import_module;

  # Perform import/fix/export
  my $catmandu_input;
  if (! defined($opt->{oimport}) || ! %{$opt->{oimport}}) {
	  $catmandu_input = $import_module->new();
  } else {
	  $catmandu_input = $import_module->new($opt->{oimport});
  }

  my $catmandu_fixer = $fix_module->new("file_name" => $opt->{fixes});

  my $catmandu_output;
  if (! defined($opt->{oexport}) || ! %{$opt->{oexport}}) {
	  $catmandu_output = $export_module->new();
  } else {
	  $catmandu_output = $export_module->new($opt->{oexport});
  }

  $catmandu_fixer->fixer->fix($catmandu_input->importer)->each(sub {
    my $item = shift;
    my $item_id = $item->{'administrativeMetadata'}->{'recordWrap'}->{'recordID'}->[0]->{'_'};
    try {
    	$catmandu_output->out->add($item);
        $logger->info(sprintf("Adding item %s.", $item_id));
    } catch {
        my $msg;
        if ($_->can('message')) {
            $msg = sprintf("Error while adding item %s: %s", $item_id, $_->message);
        } else {
            $msg = sprintf("Error while adding item %s: %s", $item_id, $_);
        }
        $logger->error($msg);
    };
  });

}

1;

__END__

=head1 NAME

Datahub::Factory::Command::transport - Implements the 'transport' command.

=head1 DESCRIPTION
This command allows datamanagers to (a) fetch data from a (local) source (b)
transform the data to LIDO using a fix (c) upload the LIDO transformed data to
a Datahub instance.

=head1 METHODS

=head2 abstract

 abstract();

=head2 description

 description();

=head2 execute

 execute();

=head2 opt_spec

 opt_spec();

=head2 validate_args

 validate_args();


=cut

