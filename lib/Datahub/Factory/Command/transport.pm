package Datahub::Factory::Command::transport;

use Datahub::Factory::Sane;

use parent 'Datahub::Factory::Cmd';

use Module::Load;
use Catmandu;
use Datahub::Factory;
use namespace::clean;

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

	if ( ! $opt->{pipeline} ) {
		# Only require the CLI switches if no pipeline file was specified
		if ( ! $opt->{importer} ) {
			$self->usage_error("Importer is missing");
		}

		if ( ! $opt->{exporter} ) {
			$self->usage_error("Exporter is missing");
		}

		if ( ! $opt->{fixes} ) {
			$self->usage_error("Fixes are missing");
		}

		if ( $opt->{importer} eq "Adlib" ) {
			if ( ! $opt->{oimport}->{file_name} ) {
				$self->usage_error("Adlib: Import file is missing")
			}
		}

		if ( $opt->{importer} eq "TMS" ) {
			if ( ! $opt->{oimport}->{db_name} ) {
				$self->usage_error("TMS: database name is missing")
			}

			if ( ! $opt->{oimport}->{db_user} ) {
				$self->usage_error("TMS: database user is missing")
			}

			if ( ! $opt->{oimport}->{db_password} ) {
				$self->usage_error("TMS: database user password is missing")
			}

			if ( ! $opt->{oimport}->{db_host} ) {
				$self->usage_error("TMS: database host is missing")
			}
		}

		if ( $opt->{exporter} eq "Datahub" ) {
			# This should move to a separate module
			if ( ! $opt->{oexport}->{datahub_url} ) {
				$self->usage_error("Datahub: the URL to the datahub instance is missing")
			}

			if ( ! $opt->{oexport}->{oauth_client_id} ) {
				$self->usage_error("Datahub OAUTH: the client id is missing")
			}

			if ( ! $opt->{oexport}->{oauth_client_secret} ) {
				$self->usage_error("Datahub OAUTH: the client secret is missing")
			}

			if ( ! $opt->{oexport}->{oauth_username} ) {
				$self->usage_error("Datahub OAUTH: the client username is missing")
			}

			if ( ! $opt->{oexport}->{oauth_password} ) {
				$self->usage_error("Datahub OAUTH: the client passowrd is missing")
			}
		}
	} else {
		
	}

	# no args allowed but options!
	$self->usage_error("No args allowed") if @$args;
}

sub execute {
  my ($self, $opt, $args) = @_;

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

