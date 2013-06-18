requires 'Data::Section::Simple';
requires 'FindBin::libs';
requires 'HTTP::Date';
requires 'Plack::App::DataSection';
requires 'Plack::App::Directory';
requires 'Text::Markdown';
requires 'Text::Xslate';
requires 'URI';
requires 'parent';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
    requires 'perl', '5.008_001';
};

on test => sub {
    requires 'HTTP::Message';
    requires 'Plack::Test';
    requires 'Test::More', "0.98";
};

on develop => sub {
    requires 'Test::Perl::Critic';
};
