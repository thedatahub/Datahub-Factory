#!perl

use strict;
use warnings;

use Try::Tiny;
use Datahub::Factory::Sane;

use Module::Load;
use Catmandu;
use Catmandu::Util qw(data_at);
use Datahub::Factory;
use namespace::clean;

use Redis::JobQueue qw(
    DEFAULT_SERVER
    DEFAULT_PORT
 
    E_NO_ERROR
    E_MISMATCH_ARG
    E_DATA_TOO_LARGE
    E_NETWORK
    E_MAX_MEMORY_LIMIT
    E_JOB_DELETED
    E_REDIS
);
use Redis::JobQueue::Job qw(
    STATUS_CREATED
    STATUS_WORKING
    STATUS_COMPLETED
);

my $server = sprintf('%s:%s', DEFAULT_SERVER, DEFAULT_PORT);

my $jq;

my $r = try {
    $jq = Redis::JobQueue->new(
        redis => $server
    );
    return 0;
} catch {
    return 1;
};

if (defined($r) && $r == 1) {
    exit $r;
}

sub exporter {
    my $job = shift;
    my ($exporter, $export_opts, $workload, $item_id, $counter) = @{$job->workload};
    my $export_module;
    try {
        $export_module = Datahub::Factory->exporter($exporter)->new($export_opts);
    } catch {
        $job->result(sprintf('%s at [plugin_exporter_%s]', $_, $exporter));
        return;
    };
    my $e = try {
        $export_module->add($workload);
    } catch {
        my $error_msg;
        # $item_id can be undefined if it isn't set in the source, but this
        # is only discovered when exporting (and not during fixing)
        my $id_type = 'id';
        if (!defined($item_id)) {
            $item_id = $counter;
            $id_type = 'counted';
        }
        if ($_->can('message')) {
            $error_msg = sprintf('Item %s (%s): could not export item: %s', $item_id, $id_type, $_->message);
        } else {
            $error_msg = sprintf('Item %s (%s): could not export item: %s', $item_id, $id_type, $_);
        }
        return $error_msg;
    };
    my $result;
    if (defined($e)) {
        # End the processing of this record, go to the next one.
        $result = $e;
    } else {
        $result = $workload;
    }
    $job->result($result);
}

my $job;
while ($job = $jq->get_next_job(queue => 'exporter', blocking => 1)) {
    $job->status(STATUS_WORKING);
    $jq->update_job($job);

    exporter($job);

    $job->status(STATUS_COMPLETED);
    $jq->update_job($job);
}

exit 0;
