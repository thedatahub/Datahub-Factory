package Datahub::Factory::Fixer;

use Datahub::Factory::Sane;

use Catmandu;
use Moose::Role;

has fixer => (is => 'lazy');
has logger    => (is => 'lazy');

sub _build_logger {
    my $self = shift;
    return Log::Log4perl->get_logger('datahub');
}

sub execute {
    my ($self, $item) = @_;
    return $self->fixer->fix($item);
}

1;
