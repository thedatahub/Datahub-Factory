_Datahub::Factory_ is an application that extracts data from _Collection Management Systems_, converts it to [LIDO](http://network.icom.museum/cidoc/working-groups/lido/what-is-lido/) and submits it to a [Datahub for Museums](https://github.com/thedatahub/Datahub).

It is written in [Perl](https://www.perl.org/) and uses [Catmandu](http://librecat.org/) as the underlying framework.

# Using Datahub::Factory
_Datahub::Factory_ can extract data from data dumps (usually in XML) or directly from the API of the Collection Management System (CMS for short). It does this by using specific _Importer_ plugins, based around _Catmandu_ modules.

At the moment, it includes support for:

* [_The Museum System_](http://www.gallerysystems.com/products-and-services/tms/)
* [_Adlib_](http://www.adlibsoft.nl/) (API and dump)
* [_Collective Access_](http://collectiveaccess.org/) (API)

By default, it will convert data to LIDO and attempt to submit it to a Datahub. However, this can be changed by changing the _Exporter_ plugin:

* [Datahub for Museums](https://github.com/thedatahub/Datahub) (the default)
* [LIDO](http://network.icom.museum/cidoc/working-groups/lido/what-is-lido/) (an XML dump)
* [YAML](http://yaml.org/)

To convert between data formats, we use the powerful [Catmandu Fixing Language](https://github.com/LibreCat/Catmandu/wiki/Fixes-Cheat-Sheet), so it is theoretically possible to convert between a limitless amount of formats.

# Under the hood

# More information
