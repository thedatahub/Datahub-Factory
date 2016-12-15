package Datahub::Factory::TMS::Import;

use Moo;
use Catmandu;
use strict;

use DBI;
use Log::Log4perl;
use Config::Simple;

use Data::Dumper qw(Dumper);

use Datahub::Factory::TMS::Import::Index;

has db_host     => (is => 'ro', required => 1);
has db_name     => (is => 'ro', required => 1);
has db_user     => (is => 'ro', required => 1);
has db_password => (is => 'ro', required => 1);


has importer  => (is => 'lazy');
has logger    => (is => 'lazy');

sub _build_logger {
    my $self = shift;
    return Log::Log4perl->get_logger('datahub');
}

sub _build_importer {
    my $self = shift;
    my $dsn = sprintf('dbi:mysql:%s', $self->db_name);
    my $query = 'select * from vgsrpObjTombstoneD_RO;';
    my $importer = Catmandu->importer('DBI', dsn => $dsn, host => $self->db_host, user => $self->db_user, password => $self->db_password, query => $query, encoding => ':iso-8859-1');
    # Add indices
    $self->logger->info('Creating indices on TMS tables.');
    Datahub::Factory::TMS::Import::Index->new(
        db_host => $self->db_host,
        db_name => $self->db_name,
        db_user => $self->db_user,
        db_password => $self->db_password
    );
    return $importer;
}



1;