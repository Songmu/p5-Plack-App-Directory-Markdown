requires 'Data::Section::Simple';
requires 'Plack';
requires 'Plack::App::DataSection';
requires 'Text::Markdown';
requires 'Text::Xslate';

on build => sub {
    requires 'ExtUtils::MakeMaker', '6.36';
    requires 'HTTP::Request::Common';
    requires 'HTTP::Response';
    requires 'Test::More';
};
