# NAME

Datahub::Factory - A conveyor belt which transforms data from an input format
to an output format before pushing it to a Datahub instance.

# SYNOPSIS

    use Datahub::Factory;

# DESCRIPTION

Datahub::Factory is a conveyor belt which does two things:

* Data is converted from an input format to an output format leveraging
  Catmandu.
* The output is pushed to an instance of the Datahub.

The factory contains a logger which can be configured via 'conf/log4perl.conf'.
If conversion or push fails, the error is logged to a configurable log
destination.

# AUTHOR

Pieter De Praetere <pieter@packed.be>
Matthias Vandermaesen <matthias.vandermaesen@vlaamsekunstcollectie.be>

# COPYRIGHT

Copyright 2016 - Pieter De Praetere

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the GPLv3 terms.
