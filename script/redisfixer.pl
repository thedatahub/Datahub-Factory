#!perl

use strict;
use warnings;

use Try::Tiny;

use Data::Dumper qw(Dumper);
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

sub redis_fixer {
    my $job = shift;
    my ($fixer, $fix_opts, $workload, $counter) = @{$job->workload};
    my $fix_module;
    try {
        $fix_module = Datahub::Factory->fixer($fixer)->new($fix_opts);
    } catch {
        $job->result(sprintf('%s at [plugin_fixter_%s]', $_, $fixer));
        return;
    };
    my $f = try {
                $fix_module->fixer->fix($workload);
    } catch {
                my $error_msg;
                if ($_->can('message')) {
                    $error_msg = sprintf('Item %d (counted): could not execute fix: %s', $counter, $_->message);
                } else {
                    $error_msg = sprintf('Item %d (counted): could not execute fix: %s', $counter, $_);
                }
                return $error_msg;
    };
    my $result;
    if (defined($f)) {
        # End the processing of this record, go to the next one.
        $result = $f;
    } else {
        $result = $workload;
    }
    $job->result($result);
}

my $job;
while ($job = $jq->get_next_job(queue => 'fixer', blocking => 1)) {
    $job->status(STATUS_WORKING);
    $jq->update_job($job);

    redis_fixer($job);

    $job->status(STATUS_COMPLETED);
    $jq->update_job($job);
}

exit 0;
