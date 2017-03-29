package Datahub::Factory::Redis::Jobs;

use Datahub::Factory::Sane;
use Moo;

use Redis::JobQueue qw(
    DEFAULT_SERVER
    DEFAULT_PORT
);

has conn => (is => 'lazy');

sub _build_conn {
    my $self = shift;
    return Redis::JobQueue->new(
        redis => sprintf('%s:%s', DEFAULT_SERVER, DEFAULT_PORT)
    );
}

1;