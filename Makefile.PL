use inc::Module::Install;
name 'Plack-App-Directory-Markdown';
all_from 'lib/Plack/App/Directory/Markdown.pm';

requires 'Plack';
requires 'Text::Xslate';
requires 'Text::Markdown';
requires 'Data::Section::Simple';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
