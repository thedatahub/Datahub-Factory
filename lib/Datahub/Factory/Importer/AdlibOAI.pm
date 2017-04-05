package Datahub::Factory::Importer::AdlibOAI;

use Datahub::Factory::Sane;

use Moo;
use Catmandu;
use namespace::clean;

with 'Datahub::Factory::Importer';

has fqdn             => (is => 'ro', required => 1);
has port             => (is => 'ro', default => '80');
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
        $importer->oai->credentials($netloc, '', $self->username, $self->password);
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

1;

__END__

=encoding utf-8

=head1 NAME

Datahub::Factory::Importer::AdlibOAI - Import data from L<Adlib|http://www.adlibsoft.nl/> OAI endpoints

=head1 SYNOPSIS

    use Datahub::Factory::Importer::Adlib;
    use Data::Dumper qw(Dumper);

    my $adlib = Datahub::Factory::Importer::Adlib->new(
        file_name => '/tmp/export.xml',
        data_path => 'recordList.record.*'
    );

    $adlib->importer->each(sub {
        my $item = shift;
        print Dumper($item);
    });

=head1 DESCRIPTION

Datahub::Factory::Importer::Adlib uses L<Catmandu|http://librecat.org/Catmandu/> to fetch a list of records
from an AdlibXML data dump. It returns an L<Importer|Catmandu::Importer>.

=head1 PARAMETERS

=over

=item C<file_name>

Location of the Adlib XML data dump. It expects AdlibXML.

=item C<data_path>

Optional parameter that indicates where the records are in the XML tree. It uses L<Catmandu::Fix|https://github.com/LibreCat/Catmandu/wiki/Fixes-Cheat-Sheet> syntax.
By default, records are in the C<recordList.record.*> path.

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
