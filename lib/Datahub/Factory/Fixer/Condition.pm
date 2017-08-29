package Datahub::Factory::Fixer::Condition;

use strict;
use warnings;

use Datahub::Factory;

use Moo;
use Catmandu;
use Catmandu::Util qw(data_at);
use namespace::clean;

has fixer        => (is => 'ro', required => 1);
has fixer_module => (is => 'lazy' );

sub _build_fixer_module {
    my $self = shift;
    return $self->fixer->{'plugin'};
}

sub get_fixers {
    my ($self, $args) = @_;
    my $fixers;

    # Init the 'default' fixer if no conditionals are set in configuration.

    if (!defined($self->fixer->{'conditionals'})) {
        my $file_name = $self->fixer->{$self->fixer_module}->{'options'}->{'file_name'};
        $fixers->{'default'} = Datahub::Factory->fixer($self->fixer_module)->new(
            'file_name' => $file_name
        );

        return $fixers;
    }

    # Init conditional fixers if set

    my $conditionals = $self->fixer->{'conditionals'};
    foreach my $conditional (keys %$conditionals) {
        $fixers->{$conditional} = Datahub::Factory->fixer($self->fixer_module)->new(
           'file_name' => $conditionals->{$conditional}->{'options'}->{'file_name'}
        );
    }

    return $fixers;
}

sub fix_module {
    my ($self, $fixers, $item) = @_;

    # Fetch the 'default' fixer if no conditional fixers were defined

    if (defined($fixers->{'default'})) {
        return $fixers->{'default'};
    }

    # Fetch the appropriate conditional fixer

    my $condition_path = $self->fixer->{$self->fixer_module}->{'options'}->{'condition'};
    my $condition_r = data_at($condition_path, $item);

    $condition_r //= 'Undefined condition';

    if ($condition_r eq 'Undefined condition') {
        Catmandu::BadVal->throw(
            'message' => sprintf('Condition path "%s" did not yield a value from item.', $condition_path)
        );
    }

    my $conditionals = $self->fixer->{'conditionals'};
    foreach my $conditional (keys %$conditionals) {
        my $condition_l = $conditionals->{$conditional}->{'options'}->{'condition'};

        if ($condition_l eq $condition_r) {
            return $fixers->{$conditional};
        }
    }

    Catmandu::BadVal->throw(
        'message' => sprintf('Fixer condition "%s" did not yield a defined fixer', $condition_r)
    );
}

1;

__END__

