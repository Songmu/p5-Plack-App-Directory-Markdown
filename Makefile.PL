use inc::Module::Install;
name 'Plack-App-Directory-Markdown';
all_from 'lib/Plack/App/Directory/Markdown.pm';

requires 'Plack';
requires 'Text::Xslate';
requires 'Text::Markdown';
requires 'Data::Section::Simple';
requires 'Plack::App::DataSection';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
test_requires 'HTTP::Request::Common';
test_requires 'HTTP::Response';

install_script 'bin/pad-markdown.pl';

auto_set_repository;
auto_include;
WriteAll;
