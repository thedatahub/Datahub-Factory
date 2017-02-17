requires 'perl', '5.008005';

# requires 'Some::Module', 'VERSION';

requires 'App::Cmd';
requires 'Config::Simple';
requires 'Catmandu', '1.0304';
requires 'Catmandu::LIDO';
requires 'Catmandu::Store::Datahub';
requires 'Catmandu::Store::Resolver';
requires 'Lido::XML';
requires 'Log::Any';
requires 'Log::Log4perl';
requires 'LWP::UserAgent';
requires 'Module::Load';
requires 'Moo';
requires 'MooX::Aliases';
requires 'MooX::Role::Logger';
requires 'namespace::clean';
requires 'Sub::Exporter';
requires 'WebService::Rackspace::CloudFiles', '1.10';
requires 'Catmandu::OAI';

on test => sub {
    requires 'Test::More', '0.96';
};
