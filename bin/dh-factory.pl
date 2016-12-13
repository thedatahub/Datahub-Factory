#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Getopt::Long;
use Module::Load;
use Log::Any::Adapter;
use Log::Log4perl;

use Catmandu;
use Catmandu::Sane;

# Logger
Log::Any::Adapter->set('Log4perl');
Log::Log4perl::init('conf/log4perl.conf');

my $logger = Log::Log4perl->get_logger('datahub');


# CLI Arguments
my ($importer, $exporter, $fixes, $import_options, $export_options, $store_options);

GetOptions("importer=s" => \$importer, "exporter:s" => \$exporter, "fixes=s" => \$fixes, "oimport=s%" => \$import_options, "oexport:s%" => \$export_options, "ostore=s%" => \$store_options);

# Load modules
my $store_module = 'Datahub::Store';
autoload $store_module;
my $fix_module = 'Datahub::Fix';
autoload $fix_module;

my $import_module = sprintf("%s::Import", $importer);
autoload $import_module;

my $export_module;
if (defined($exporter) && $exporter ne '') {
    $export_module = sprintf("%s::Export", $exporter);
    autoload $export_module;
}

# Perform import/fix/store/export
my $catmandu_importer = $import_module->new(%$import_options);
my $catmandu_fixer = $fix_module->new(file_name => $fixes);
my $catmandu_out;
if (defined($exporter) && $exporter ne '') {
    $catmandu_out = $export_module->new(%$export_options);
} else {
    $catmandu_out = $store_module->new(%$store_options);
}

$catmandu_fixer->fixer->fix($catmandu_importer->importer)->each(sub {
    my $item = shift;
    my $item_id = $item->{'administrativeMetadata'}->{'recordWrap'}->{'recordID'}->[0]->{'_'};
    try {
        $catmandu_out->out->add($item);
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

1;