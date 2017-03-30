package Datahub::Factory::Command::worker;

use Datahub::Factory::Sane;

use parent 'Datahub::Factory::Cmd';

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
    STATUS_FAILED
);

use Data::Dumper qw(Dumper);

sub abstract { "Transport data from a data source to a datahub instance" }

sub description { "Long description on blortex algorithm" }

sub opt_spec {
	return (
		[ "queue|p=s", "Queue this worker runs against"],
        [ "server|s:s", "FQDN or IP address of the REDIS server"],
        [ "port|P:s", "Port the REDIS server is listening on"]
	);
}

sub validate_args {
	my ($self, $opt, $args) = @_;

    if (! $opt->{'queue'}) {
        $self->usage_error('The --queue flag is required.');
    }
	# no args allowed but options!
	$self->usage_error("No args allowed") if @$args;
}

sub execute {
    my ($self, $arguments, $args) = @_;
    my @redis = (DEFAULT_SERVER, DEFAULT_PORT);
    if (defined($arguments->{'server'})) {
        $redis[0] = $arguments->{'server'};
    }
    if (defined($arguments->{'port'})) {
        $redis[1] = $arguments->{'port'};
    }
    my $redis_server = join(':', @redis);

    # Should die painfully if failed
    my $jq = Redis::JobQueue->new(
        redis => $redis_server
    );

    # Loop through the job queue
    my $job;
    while ($job = $jq->get_next_job(queue => $arguments->{'queue'}, blocking => 1)) {
        $job->status(STATUS_WORKING);
        $jq->update_job($job);

        $self->execute_job($job);

        if ($job->{'status'} ne STATUS_FAILED) {
            $job->status(STATUS_COMPLETED);
        }
        $jq->update_job($job);
    }
}

sub execute_job {
    my ($self, $job) = @_;
    my ($module_name, $module_plugin, $module_options, $item, $counter, $item_id) = @{$job->workload};
    my $module;
    try {
        # This looks extremely dirty, but is equivalent to
        # $fix_module = Datahub::Factory->fixer($fixer)->new($fix_opts);
        # but with a generic $fix_module and 'fixer' method
        $module = Datahub::Factory->$module_name($module_plugin)->new($module_options);
    } catch {
        $job->result(sprintf('%s at [plugin_%s_%s]', $_, $module_name, $module_plugin));
        $job->status(STATUS_FAILED);
        return;
    };

    my $result;
    my $r = try {
        $module->execute($item);
    } catch {
        my $error_msg;
        my $item_id_type = 'id';
        if (!defined($item_id)) {
            $item_id = $counter;
            $item_id_type = 'counted';
        }

        if ($_->can('message')) {
            $error_msg = sprintf('Item %s (%s): could not execute %s->execute($item): %s', $item_id, $item_id_type, $module_plugin, $_->message);
        } else {
            $error_msg = sprintf('Item %s (%s): could not execute %s->execute($item): %s', $item_id, $item_id_type, $module_plugin, $_);
        }

        return $error_msg;
    };

    if (defined($r)) {
        # An error occurred
        $job->status(STATUS_FAILED);
        $result = $r;
    } else {
        # ->execute() works on the parameter itself, so no return value
        $result = $item;
    }

    $job->result($result);
    return;
}

1;