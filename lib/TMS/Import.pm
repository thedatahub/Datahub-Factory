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
    my $query = 'select * from objects';
    my $importer = Catmandu->importer('DBI', dsn => $dsn, host => $self->db_host, user => $self->db_user, password => $self->db_password, query => $query);
    return $importer;
}

1;