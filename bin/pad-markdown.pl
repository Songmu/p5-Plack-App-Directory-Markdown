#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Getopt::Long;
use Pod::Usage;
use Plack::Loader;

use Plack::App::Directory::Markdown;

=head1 DESCRIPTION

Plack::App::Diectory::Markdown kick start script.

=head1 SYNOPSIS

    % pad.pl

    Options:
        port=i
        host=s
        root=s
        encoding=s
        title=s
        tx_path=s
        markdown_class=s
        markdown_ext=s

=cut

GetOptions(
    \my %options, qw/
        help
        port=i
        host=s
        root=s
        encoding=s
        title=s
        tx_path=s
        markdown_class=s
        markdown_ext=s
    /,
) or pod2usage(2);
pod2usage(1) if $options{help};

my $port = delete $options{port} || 9119;
my $host = delete $options{host} || '0.0.0.0';

my $app = Plack::App::Directory::Markdown->new(%options)->to_app;

Plack::Loader->auto(
    port => $port,
    host => $host,
)->run($app);

