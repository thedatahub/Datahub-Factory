package TMS::Import;

use Moo;
use Catmandu;
use strict;

use Data::Dumper qw(Dumper);

has db_host     => (is => 'ro', required => 1);
has db_name     => (is => 'ro', required => 1);
has db_user     => (is => 'ro', required => 1);
has db_password => (is => 'ro', required => 1);


has importer  => (is => 'lazy');

sub _build_importer {
    my $self = shift;
    my $dsn = sprintf('dbi:mysql:%s', $self->db_name);
    my $query = 'select * from objects';
    my $importer = Catmandu->importer('DBI', dsn => $dsn, host => $self->db_host, user => $self->db_user, password => $self->db_password, query => $query, encoding => ':iso-8859-1');
    $self->prepare();
    return $importer;
}

sub prepare {
    my $self = shift;
    $self->__classifications();
    $self->__period();
    $self->__dimensions();
}

sub prepare_call {
    my ($self, $import_query, $store_table) = @_;
    my $importer = Catmandu->importer(
        'DBI',
        dsn      => sprintf('dbi:mysql:%s', $self->db_name),
        host     => $self->db_host,
        user     => $self->db_user,
        password => $self->db_password,
        query    => $import_query
    );
    my $store = Catmandu->store(
        'DBI',
        data_source => sprintf('dbi:SQLite:/tmp/tms_import.%s.sqlite', $store_table),
    );
   $importer->each(sub {
            my $item = shift;
            my $bag = $store->bag();
            # first $bag->get($item->{'_id'})
            $bag->add($item);
        });
}

sub __classifications {
    my $self = shift;
    $self->prepare_call('select ClassificationID as _id, Classification as term from Classifications', 'classifications');
}

sub __period {
    my $self = shift;
    $self->prepare_call('select ObjectID as _id, Period as term from ObjContext', 'periods')
}

sub __dimensions {
    my $self = shift;
    # NEIN NEIN NEIN: mergen op _id!
    # tijdelijk object met alles tesamen
    # select o.ObjectNumber
    my $query = "SELECT o.ObjectNumber as objectid, d.Dimension as dimension, t.DimensionType as type, e.Element as element, u.UnitName as unit
    FROM Dimensions d, DimItemElemXrefs x, objects o, DimensionUnits u, DimensionElements e, DimensionTypes t
    WHERE
    x.TableID = '108' and
    x.ID = o.ObjectID and
    x.DimItemElemXrefID = d.DimItemElemXrefID and
    d.PrimaryUnitID = u.UnitID and
    x.ElementID = e.ElementID and
    d.DimensionTypeID = t.DimensionTypeID;";
    my $importer = Catmandu->importer(
        'DBI',
        dsn      => sprintf('dbi:mysql:%s', $self->db_name),
        host     => $self->db_host,
        user     => $self->db_user,
        password => $self->db_password,
        query    => $query
    );
    my $merged = {};
    $importer->each(sub {
        my $item = shift;
        my $objectid = $item->{'objectid'};
        if (exists($merged->{$objectid})) {
            push @{$merged->{$objectid}->{'dimensions'}}, $item;
        } else {
            $merged->{$objectid} = {
                'dimensions' => [$item]
            };
        }
    });
    my $store = Catmandu->store(
        'DBI',
        data_source => sprintf('dbi:SQLite:/tmp/tms_import.%s.sqlite', 'dimensions'),
    );
    while (my ($object_id, $data) = each %{$merged}) {
        $store->bag->add({
            '_id' => $object_id,
            'dimensions' => $data->{'dimensions'}
        });
    }
}

1;