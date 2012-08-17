use inc::Module::Install;
name 'Plack-App-Directory-Markdown';
all_from 'lib/Plack/App/Directory/Markdown.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
