package Datahub::Factory;

use strict;
use 5.008_005;
our $VERSION = '0.01';

1;
__END__

=encoding utf-8


=head1 NAME

Datahub::Factory - A conveyor belt which transforms data from an input format
to an output format before pushing it to a Datahub instance.

=head1 SYNOPSIS

    Datahub::Factory consists of two elements: a library (C<Datahub::FactoryC<) and a conversion script (C<dh-factory.plC<).

=head1 DESCRIPTION

Datahub::Factory is a conveyor belt which does two things:

=over

=item Data is converted from an input format to an output format leveraging
  Catmandu.

=item The output is pushed to an instance of the Datahub.

=back

Internally, Datahub::Factory uses Catmandu modules.

=head1 USAGE

Invoke the perl script in C<bin>.


  perl bin/dh-factory.pl \
    --importer=Adlib \
    --fixes=/path/to/catmandufixfile.fix \
    --oimport file_name=/path/to/importfile.xml \
    --ostore datahub_url="http://www.datahub.app" \
    --ostore oauth_client_id=client_id \
    --ostore oauth_client_secret=client_secret \
    --ostore oauth_username=user \
    --ostore oauth_password=password

=head2 CLI

=head3 Options

=over

=item C<--importer>: select the importer to use. Supported importers are in C<lib>and are of the form C<$importer_name::Import.pm>. You only have to provide C<$importer_name> By default C<Adlib>is the only supported importer.

=item C<--fixes>: location (path) of the file containing the fixes that have to be applied.

=item C<--exporter>: select the exporter to use. Uses the same format as C<--importer>, but only supports C<Lido> Optional, if it isn't set, the default internal store is used. If it is set, the store isn't used.

=item C<--oimport>: set C<--importer>options like C<--oimport _option_=_value_> Options are specific to the importer used (see below).

=item C<--ostore>: set options for the default Datahub store. Uses the same syntax as C<--oimport>.

=item C<--oexport>: set options for C<--exporter>using the same syntax as C<--oimport>, but is only required if C<--exporter>is used.

=back

=head3 Specific options

=head4 Importer

=over

=item C<file_name>: path of the XML dump that the C<--importer>will import from.

=back

=head4 Exporter

=over

=item C<file_name>: path of the file the C<--exporter>will write to.

=back

=head4 Store

=over

=item C<datahub_url>. URL of the datahub (e.g. _http://www.datahub.app_).

=item C<oauth_client_id>. OAuth2 client_id.

=item C<oauth_client_secret>. OAuth2 client_secret.

=item C<oauth_username>. OAuth2 username.

=item C<oauth_password>. OAuth2 password.

=back

=head1 AUTHOR

=over

=item Pieter De Praetere <pieter@packed.be>

=item Matthias Vandermaesen <matthias.vandermaesen@vlaamsekunstcollectie.be>

=back

=head1 COPYRIGHT

Copyright 2016 - PACKED vzw

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GPLv3.

=cut
