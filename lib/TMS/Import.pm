package TMS::Import;

use Moo;
use Catmandu;
use strict;

has db_host     => (is => 'ro', required => 1);
has db_name     => (is => 'ro', required => 1);
has db_user     => (is => 'ro', required => 1);
has db_password => (is => 'ro', required => 1);


has importer  => (is => 'lazy');

sub _build_importer {
    my $self = shift;
    my $dsn = sprintf('dbi:mysql:%s', $self->db_name);
    my $query = 'select * from objects where ClassificationID <> 0 limit 10';
    my $importer = Catmandu->importer('DBI', dsn => $dsn, host => $self->db_host, user => $self->db_user, password => $self->db_password, query => $query);
    $self->prepare();
    return $importer;
}

sub prepare {
    my $self = shift;
    $self->__classifications();
}

sub __classifications {
    my $self = shift;
    #catmandu import DBI --dsn "dbi:mysql:tms_kmska" --user datahub --password datahub --query "select ClassificationID as _id, Classification as term from Classifications" to DBI --data_source "dbi:SQLite:/vagrant/Datahub-Fixes/kmska_classifications.sqlite"
    my $importer = Catmandu->importer(
        'DBI',
        dsn      => sprintf('dbi:mysql:%s', $self->db_name),
        host     => $self->db_host,
        user     => $self->db_user,
        password => $self->db_password,
        query    => 'select ClassificationID as _id, Classification as term from Classifications'
    );
    my $store = Catmandu->store(
        'DBI',
        data_source => 'dbi:mysql:datahub',
        host        => $self->db_host,
        username    => $self->db_user,
        password    => $self->db_password
    );
    $importer->each(sub {
        my $item = shift;
        my $bag = $store->bag('classifications');
        $bag->add($item);
    });
}

1;