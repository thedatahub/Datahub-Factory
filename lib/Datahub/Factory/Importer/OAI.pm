package Datahub::Factory::Importer::OAI;

use strict;
use warnings;

use Catmandu::Importer::OAI;
use Moo;

with 'Datahub::Factory::Importer';

has endpoint        => (is => 'ro', required => 1);
has metadata_prefix => (is => 'ro', default => sub {
    return 'oai_lido';
});
has set             => (is => 'ro');
has from            => (is => 'ro');
has until           => (is => 'ro');


sub _build_importer {
    my $self = shift;
    my $importer = Catmandu::Importer::OAI->new(
        url            => $self->url,
        metadataPrefix => $self->metadata_prefix,
        from           => $self->from,
        until          => $self->until,
        set            => $self->set
    );
    return $importer;
}

1;
__END__

=encoding utf-8

=head1 NAME

Datahub::Factory::Importer::OAI - Import data from an L<OAI-PMH|https://www.openarchives.org/pmh/> endpoint

=head1 SYNOPSIS

    use Datahub::Factory::Importer::OAI;
    use Data::Dumper qw(Dumper);

    my $oai = Datahub::Factory::Importer::OAI->new(
        url            => 'https://biblio.ugent.be/oai',
        metadataPrefix => 'oai_dc',
        set            => '2011'
    );

    $oai->importer->each(sub {
        my $item = shift;
        print Dumper($item);
    });

=head1 DESCRIPTION

Datahub::Factory::Importer::OAI imports data from an OAI-PMH endpoint. By default it uses the C<ListRecords>
verb to return all records using the I<oai_lido> format. It is possible to only return records from a single
I<Set> or those created, modified or deleted between two dates (I<from> and I<until>).

It automatically deals with I<resumptionTokens>, so client code does not have to implement paging.

=head1 PARAMETERS

Only the C<endpoint> parameter is required.

=over

=item C<endpoint>

URL of the OAI endpoint.

=item C<metadata_prefix>

Any metadata prefix the endpoint supports. Defaults to C<oai_lido>.

=item C<set>

Optionally, a set to get records from.

=item C<from>

Optionally, a I<must_be_older_than> date.

=item C<until>

Optionally, a I<must_be_younger_than> date.

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
