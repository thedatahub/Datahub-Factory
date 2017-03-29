package Datahub::Factory::Redis::Queue;

use Datahub::Factory::Sane;

use Moo;
use Datahub::Factory::Redis::Jobs;
use Redis::JobQueue::Job qw(
    STATUS_CREATED
    STATUS_WORKING
    STATUS_COMPLETED
    STATUS_FAILED
);

has queue_name => (is => 'ro');

has queue => (is => 'lazy');

sub _build_queue {
    my $self = shift;
    return Datahub::Factory::Redis::Jobs->new()->conn;
}

sub add {
    my ($self, $workload) = @_;
    return $self->queue->add_job({
        queue    => $self->queue_name,
        workload => $workload,
        expire   => 12*60*60,
    });
}

sub get {
    my ($self, $job_id) = @_;
    return $self->queue->get_job_data($job_id);
}

1;