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

# USAGE

Invoke the perl script in `bin`:

```
perl bin/convert.pl
  --importer=Adlib
  --fixes=/path/to/catmandufixfile.fix
  --oimport file_name=/path/to/importfile.xml
  --ostore datahub_url="http://datahub.app"
  --ostore oauth_client_id=4rrn6jj0i7wgs8wggw0s0wcwcsok4osc4w800wk8wwog88ks4s
  --ostore oauth_client_secret=8naz6fkyh7480wksc0c4woss8kkkoc4g4cc8s8ocg4ocgcgwk
  --ostore oauth_password=admin
  --ostore oauth_username=admin
```

# AUTHOR

Pieter De Praetere <pieter@packed.be>
Matthias Vandermaesen <matthias.vandermaesen@vlaamsekunstcollectie.be>

# COPYRIGHT

Copyright 2016 - Pieter De Praetere

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the GPLv3 terms.
