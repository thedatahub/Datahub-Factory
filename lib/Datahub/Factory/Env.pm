package Datahub::Factory::Env;

use Datahub::Factory::Sane;

use Datahub::Factory::Util qw(require_package);
use Moo;
use Catmandu;
use namespace::clean;
use Config::Simple;

with 'Datahub::Factory::Logger';

sub importer {
    my $self = shift;
    my $name = shift;
    my $ns = "Datahub::Factory::Importer";

    require_package($name, $ns)->new(@_);
}

sub fixer {
    my $self = shift;
    my $name = shift;
    my $ns = "Datahub::Factory::Fixer";
    
    require_package($name, $ns)->new(@_);
}

sub store {
    require_package('Store', 'Datahub::Factory')->new($_[1]);
}

sub exporter {
    my $self = shift;
    my $name = shift;
    my $ns = "Datahub::Factory::Exporter";
    
    require_package($name, $ns)->new(@_);
}

1;

__END__

=head1 NAME

Datahub::Factory::Env - A Datahub::Factory configuration file loader

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

