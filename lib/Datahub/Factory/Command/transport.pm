package Datahub::Factory::Command::transport;

use Datahub::Factory::Sane;

use parent 'Datahub::Factory::Cmd';

use Module::Load;
use Catmandu;
use Datahub::Factory;
use namespace::clean;

sub abstract { "Transport data from a data source to a datahub instance" }

sub description { "Long description on blortex algorithm" }

sub opt_spec {
	return (
		[ "importer|i=s",  "The importer" ],
		[ "datahub|d=s",  "The datahub instance" ],
		[ "exporter|e:s",  "The exporter"],
		[ "fixes|f=s",  "Fixes"],
		[ "oimport|oi=s%",  "import options"],
		[ "oexport|oe:s%",  "export options"],
		[ "ostore|os=s%",  "Store options"],
	);
}

sub validate_args {
	my ($self, $opt, $args) = @_;

	if ( ! $opt->{importer} ) {
		$self->usage_error("Importer is missing");
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

	if ( ! $opt->{ostore}->{datahub_url} ) {
		$self->usage_error("Datahub: the URL to the datahub instance is missing")
	}

	if ( ! $opt->{ostore}->{oauth_client_id} ) {
		$self->usage_error("Datahub OAUTH: the client id is missing")
	}

	if ( ! $opt->{ostore}->{oauth_client_secret} ) {
		$self->usage_error("Datahub OAUTH: the client secret is missing")
	}

	if ( ! $opt->{ostore}->{oauth_username} ) {
		$self->usage_error("Datahub OAUTH: the client username is missing")
	}

	if ( ! $opt->{ostore}->{oauth_password} ) {
		$self->usage_error("Datahub OAUTH: the client passowrd is missing")
	}

	# no args allowed but options!
	$self->usage_error("No args allowed") if @$args;
}

sub execute {
  my ($self, $opt, $args) = @_;

  my $logger = Datahub::Factory->log;

  # Load modules
  my $store_module = 'Datahub::Factory::Store';
  autoload $store_module;

  my $fix_module = 'Datahub::Factory::Fix';
  autoload $fix_module;

  my $import_module = sprintf("Datahub::Factory::%s::Import", $opt->{importer});
  autoload $import_module;

  # my $export_module;
  # if (defined($exporter) && $exporter ne '') {
  #   $export_module = sprintf("Datahub::Factory::%s::Export", $exporter);
  #   autoload $export_module;
  # }

  # Perform import/fix/store/export
  my $catmandu_input = $import_module->new($opt->{oimport});
  my $catmandu_fixer = $fix_module->new("file_name" => $opt->{fixes});
  my $catmandu_output = $store_module->new($opt->{ostore});
  # if (defined($exporter) && $exporter ne '') {
  #   $catmandu_output = $export_module->new(%$export_options);
  # }

  $catmandu_fixer->fixer->fix($catmandu_input->importer)->each(sub {
    my $item = shift;
    my $item_id = $item->{'administrativeMetadata'}->{'recordWrap'}->{'recordID'}->[0]->{'_'};
    try {
        $catmandu_output->out->add($item);
        $logger->info(sprintf("Adding item %s.", $item_id));
  #  } catch_case [
  #      'Catmandu::HTTPError' => sub {
  #          my $msg = sprintf("Error while adding item %s: %s", $item_id, $_->message);
  #          $logger->error($msg);
  #      },
  #      'Lido::XML::Error' => sub {
  #          my $msg = sprintf("Error while adding item %s: %s", $item_id, $_->message);
  #          $logger->error($msg);
  #      },
  # DOESN'T WORK
  #      '*' => sub {
  #          my $msg = sprintf("Error while adding item %s: %s", $item_id, $_->message);
  #          $logger->error($msg);
  #      }
  #  ];
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

	print "Everything has been initialized.  (Not really.)\n";
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

