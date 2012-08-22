#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Getopt::Long;
use Pod::Usage;
use Plack::Loader;

use Plack::App::Directory::Markdown;

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
) or pod2usage(1);
pod2usage(0) if $options{help};

my $port = $options{port} || 9119;
my $host = $options{host} || '0.0.0.0';
delete $options{port};
delete $options{host};

my $app = Plack::App::Directory::Markdown->new(%options)->to_app;

Plack::Loader->auto(
    port => $port,
    host => $host,
)->run($app);

