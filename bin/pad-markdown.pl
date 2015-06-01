#!perl
use strict;
use warnings;
use utf8;
use Plack::Runner;
use Plack::App::Directory::Markdown;

=head1 DESCRIPTION

Plack::App::Diectory::Markdown kick start script.

=head1 SYNOPSIS

    % pad-markdown.pl

    Options:
        root=s
        encoding=s
        title=s
        tx_path=s
        markdown_class=s
        markdown_ext=s
        ...and plackup options

=cut

my ($opt, $rest_argv) = Plack::App::Directory::Markdown->parse_options(@ARGV);
my $app = Plack::App::Directory::Markdown->new(%$opt)->to_app;

# fill default port
push @$rest_argv, '--port=9119' unless grep {/^(?:--?p(?:o|or|ort)?)\b/} @$rest_argv;
my $runner = Plack::Runner->new;
$runner->parse_options(@$rest_argv);
$runner->run($app);
