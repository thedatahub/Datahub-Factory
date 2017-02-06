requires 'perl', '5.008005';

# requires 'Some::Module', 'VERSION';

requires 'Module::Load';
requires 'Log::Any';
requires 'Log::Log4perl';
requires 'Moo';
requires 'LWP::UserAgent';
requires 'App::Cmd';

requires 'WebService::Rackspace::CloudFiles', '1.10';
requires 'Catmandu', '1.0304';

requires 'Catmandu::Store::Datahub';
requires 'Catmandu::Store::Resolver';
requires 'Lido::XML';
requires 'Catmandu::LIDO';

on test => sub {
    requires 'Test::More', '0.96';
};
