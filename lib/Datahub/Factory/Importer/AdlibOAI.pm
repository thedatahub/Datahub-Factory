package Datahub::Factory::Importer::AdlibOAI;

use Datahub::Factory::Sane;

use Moo;
use Catmandu;
use namespace::clean;

with 'Datahub::Factory::Importer';

has fqdn             => (is => 'ro', required => 1);
has port             => (is => 'ro', default => '80');
has realm            => (is => 'ro');
has username         => (is => 'ro');
has password         => (is => 'ro');
has problematic_ntlm => (is => 'ro', default => 0);
has url              => (is => 'ro', required => 1);
has metadataPrefix   => (is => 'ro', default => 'oai_dc');
has handler          => (is => 'ro');
has from             => (is => 'ro');
has until            => (is => 'ro');
has set              => (is => 'ro');
has listIdentifiers  => (is => 'ro');
has listSets         => (is => 'ro');
has resumptionToken  => (is => 'ro');
has dry              => (is => 'ro');
has xslt             => (is => 'ro');
has max_retries      => (is => 'ro');
has load_pid_module  => (is => 'ro', default => 0);
has pid_module       => (is => 'ro', default => 'lwp');
has pid_base_url     => (is => 'ro');
has pid_username     => (is => 'ro');
has pid_password     => (is => 'ro');


sub _build_importer {
    my $self = shift;
    my @c_args = ('url', $self->url, 'metadataPrefix', $self->metadataPrefix);
    # Unforgivably dirty
    if (defined($self->handler)) { push @c_args, ('handler', $self->handler); }
    if (defined($self->from)) { push @c_args, ('from', $self->from); }
    if (defined($self->until)) { push @c_args, ('until', $self->until); }
    if (defined($self->set)) { push @c_args, ('set', $self->set); }
    if (defined($self->listIdentifiers)) { push @c_args, ('listIdentifiers', $self->listIdentifiers); }
    if (defined($self->listSets)) { push @c_args, ('listSets', $self->listSets); }
    if (defined($self->resumptionToken)) { push @c_args, ('resumptionToken', $self->resumptionToken); }
    if (defined($self->dry)) { push @c_args, ('dry', $self->dry); }
    if (defined($self->xslt)) { push @c_args, ('xslt', $self->xslt); }
    if (defined($self->max_retries)) { push @c_args, ('max_retries', $self->max_retries); }

    my $importer = Catmandu->importer('OAI',
        @c_args
    );
    ##
    # Interfere with $importer->oai (a sub-sub class of LWP::UserAgent) to make
    # Adlib's particular interpretation of NTLM work
    if ((defined($self->username) && defined($self->password)) || defined($self->username)) {
        my $netloc = sprintf('%s:%s', $self->fqdn, $self->port);
        $importer->oai->credentials($netloc, $self->realm, $self->username, $self->password);
        if ($self->problematic_ntlm == 1) {
            $importer->oai->add_handler(response_header => sub {
                my ($response, $ua, $h) = @_;
                my $authen = $response->header('WWW-Authenticate');
                if (defined($authen)) {
                    $authen =~ s/Negotiate\s*,?\s*//i;
                    $response->header('WWW-Authenticate', $authen);
                }
                return;
            });
        }
    }
    return $importer;
}

sub __pids {
    my $self = shift;
    my $pids = Datahub::Factory->module('PID')->new(@_);
}

1;

__END__

=encoding utf-8

=head1 NAME

Datahub::Factory::Importer::AdlibOAI - Import data from L<Adlib|http://www.adlibsoft.nl/> OAI endpoints

=head1 SYNOPSIS

    use Datahub::Factory::Importer::AdlibOAI;
    use Data::Dumper qw(Dumper);

    my $adlib = Datahub::Factory::Importer::AdlibOAI->new(
        fqdn => adlib.example.org',
        url  => 'http://adlib.example.org/oai'
    );

    $adlib->importer->each(sub {
        my $item = shift;
        print Dumper($item);
    });

=head1 DESCRIPTION

Datahub::Factory::Importer::AdlibOAI uses L<Catmandu|http://librecat.org/Catmandu/> to fetch a list of records
from an Adlib OAI endpoint. It returns an L<Importer|Catmandu::Importer>.

=head1 PARAMETERS

C<Datahub::Factory::Importer::AdlibOAI> supports all the options that L<Catmandu::Importer::OAI> supports, as wel as some additional options for authentication.

=over

=item C<fqdn>

The FQDN of the OAI service you want to query. Used by L<LWP::UserAgent::credentials()|http://search.cpan.org/~oalders/libwww-perl-6.25/lib/LWP/UserAgent.pm#credentials> as part of C<$netloc>. Required.

=item C<port>

The port of the OAI service you want to query. Used by L<LWP::UserAgent::credentials()|http://search.cpan.org/~oalders/libwww-perl-6.25/lib/LWP/UserAgent.pm#credentials> as part of C<$netloc>. Optional, set to C<80> by default.

=item C<problematic_ntlm>

If set to C<1>, will attempt to strip C<WWW-Authenticate Negotiate> from the server response to work around L<this bug|https://github.com/libwww-perl/libwww-perl/issues/201>. Set to C<0> by default.

=back

=head1 ATTRIBUTES

=over

=item C<importer>

A L<Importer|Catmandu::Importer> that can be used in your script.

=back

=head1 AUTHOR

Pieter De Praetere E<lt>pieter at packed.be E<gt>

=head1 COPYRIGHT

Copyright 2017- PACKED vzw

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Datahub::Factory>
L<Catmandu>

=cut
