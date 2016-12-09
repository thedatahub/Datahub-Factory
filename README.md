# NAME

Datahub::Factory - A conveyor belt which transforms data from an input format
to an output format before pushing it to a Datahub instance.

# SYNOPSIS

    Datahub::Factory consists of two elements: a library (`Datahub::Factory`) and a conversion script (`dh-factory.pl`).

# DESCRIPTION

Datahub::Factory is a conveyor belt which does two things:

* Data is converted from an input format to an output format leveraging
  Catmandu.
* The output is pushed to an instance of the Datahub.

Internally, Datahub::Factory uses Catmandu modules.

# USAGE

Invoke the perl script in `bin`:

```
perl bin/dh-factory.pl \
  --importer=Adlib \
  --fixes=/path/to/catmandufixfile.fix \
  --oimport file_name=/path/to/importfile.xml \
  --ostore datahub_url="http://www.datahub.app" \
  --ostore oauth_client_id=client_id \
  --ostore oauth_client_secret=client_secret \
  --ostore oauth_username=user \
  --ostore oauth_password=password
```
## CLI

### Options

* `--importer`: select the importer to use. Supported importers are in `lib` and are of the form `$importer_name::Import.pm`. You only have to provide `$importer_name`. By default `Adlib` is the only supported importer.
* `--fixes`: location (path) of the file containing the fixes that have to be applied.
* `--exporter`: select the exporter to use. Uses the same format as `--importer`, but only supports `Lido`. Optional, if it isn't set, the default internal store is used. If it is set, the store isn't used.
* `--oimport`: set `--importer` options like `--oimport _option_=_value_`. Options are specific to the importer used (see below).
* `--ostore`: set options for the default Datahub store. Uses the same syntax as `--oimport`.
* `--oexport`: set options for `--exporter` using the same syntax as `--oimport`, but is only required if `--exporter` is used.

#### Specific options
##### Importer

* `file_name`: path of the XML dump that the `--importer` will import from.

##### Exporter

* `file_name`: path of the file the `--exporter` will write to.

##### Store

* `datahub_url`: URL of the datahub (e.g. _http://www.datahub.app_).
* `oauth_client_id`: OAuth2 client_id.
* `oauth_client_secret`: OAuth2 client_secret.
* `oauth_username`: OAuth2 username.
* `oauth_password`: OAuth2 password.

# AUTHOR

* Pieter De Praetere <pieter@packed.be>
* Matthias Vandermaesen <matthias.vandermaesen@vlaamsekunstcollectie.be>

# COPYRIGHT

Copyright 2016 - PACKED vzw

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GPLv3.
