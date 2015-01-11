package Plack::App::Directory::Markdown;
use strict;
use warnings;
use utf8;
our $VERSION = '0.08';

use parent 'Plack::App::Directory';
use Encode qw/encode_utf8/;
use Data::Section::Simple;
use Text::Xslate;
use HTTP::Date;
use URI::Escape qw/uri_escape/;
use Plack::Middleware::Bootstrap;
use Plack::Builder;

use Plack::Util::Accessor;
Plack::Util::Accessor::mk_accessors(__PACKAGE__, qw(title tx tx_path markdown_class markdown_ext));

sub new {
    my $cls = shift;

    my $self = $cls->SUPER::new(@_);
    $self->tx(
        Text::Xslate->new(
            path => [
                ($self->tx_path || ()),
                Data::Section::Simple->new->get_data_section,
            ],
        )
    );
    $self;
}

sub to_app {
    my $self = shift;

    my $app = $self->SUPER::to_app;

    builder {
        enable 'Bootstrap';
        $app;
    };
}

sub markdown {
    my $self = shift;

    my $md = $self->{_md} ||= do {
        my $cls = $self->markdown_class || 'Text::Markdown';
        Plack::Util::load_class($cls);

        $cls->new;
    };

    $md->markdown(@_);
}

sub serve_path {
    my($self, $env, $dir) = @_;

    if (-f $dir) {
        if ($self->is_markdown($dir)) {
            my $content = do {local $/;open my $fh,'<:encoding(UTF-8)',$dir or die $!;<$fh>};
            $content = $self->markdown($content);

            my $path = $self->remove_root_path($dir);
            $path =~ s/\.(?:markdown|mk?dn?)$//;

            my $page = $self->tx->render('md.tx', {
                path    => $path,
                title   => ($self->title || 'Markdown'),
                content => $content,
            });
            $page = encode_utf8($page);

            my @stat = stat $dir;
            return [ 200, [
                'Content-Type'   => 'text/html; charset=utf-8',
                'Last-Modified'  => HTTP::Date::time2str( $stat[9] ),
            ], [ $page ] ];
        }
        else {
            return $self->SUPER::serve_path($env, $dir);
        }
    }

    my $dir_url = $env->{SCRIPT_NAME} . $env->{PATH_INFO};

    if ($dir_url !~ m{/$}) {
        return $self->return_dir_redirect($env);
    }

    my @files;
    push @files, ({ link => "../", name => "Parent Directory" }) if $env->{PATH_INFO} ne '/';

    my $dh = DirHandle->new($dir);
    my @children;
    while (defined(my $ent = $dh->read)) {
        next if $ent eq '.' or $ent eq '..';
        push @children, $ent;
    }

    for my $basename (sort { $a cmp $b } @children) {
        my $file = "$dir/$basename";
        my $url = $dir_url . $basename;

        my $is_dir = -d $file;
        next if !$is_dir && !$self->is_markdown($file);

        my @stat = stat _;

        $url = join '/', map {uri_escape($_)} split m{/}, $url;

        if ($is_dir) {
            $basename .= "/";
            $url      .= "/";
        }
        push @files, { link => $url, name => $basename, mtime => HTTP::Date::time2str($stat[9]) };
    }

    my $path  = Plack::Util::encode_html("Index of $env->{PATH_INFO}");
    my $page  = $self->tx->render('index.tx', {
        title   => ($self->title || 'Markdown'),
        files => \@files,
        path => $path
    });
    $page = encode_utf8($page);
    return [ 200, ['Content-Type' => 'text/html; charset=utf-8'], [ $page ] ];
}

sub is_markdown {
    my ($self, $file) = @_;
    if ($self->markdown_ext) {
        my $ext = quotemeta $self->markdown_ext;
        $file =~ /$ext$/;
    }
    else {
        $file =~ /\.(?:markdown|mk?dn?)$/;
    }
}

sub remove_root_path {
    my ($self, $path) = @_;

    $path =~ s!^\./?!!;
    my $root = $self->root || '';
    $root =~ s!^\./?!!;
    $root .= '/' if $root && $root !~ m!/$!;
    $root = quotemeta $root;
    $path =~ s!^$root!!;

    $path;
}

1;

__DATA__

@@ base.tx
<head>
<meta charset="utf-8">
<title><: $title :></title>
<!-- you can locate your style.css and adjust styles -->
<link rel="stylesheet" type="text/css" media="all" href="/style.css" />
</head>
<body>
<nav class="navbar navbar-default" role="navigation">
  <div class="container-fluid">
    <div class="navbar-header">
      <button type="button" class="navbar-toggle" data-toggle="collapse" data-target="#nav-menu-1">
        <span class="sr-only">Toggle navigation</span>
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
      </button>
      <a class="navbar-brand" href="/"><: $title :></a>
    </div>
    <div class="collapse navbar-collapse" id="nav-menu-1">
      <ul class="nav navbar-nav">
        <li><a href="/">Home</a></li>
      </ul>
    </div>
  </div>
</nav>
<: block body -> { :>default body<: } :>
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js"></script>
<script src="https://google-code-prettify.googlecode.com/svn/loader/run_prettify.js"></script>
<script>$(function(){$('pre > code').addClass('prettyprint');});</script>
</body>

@@ index.tx
: cascade base;
: override body -> {
<h1><: $path :></h1>
<ul>
:   for $files -> $file {
<li><a href="<: $file.link :>"><: $file.name :></a></li>
:   }
</ul>
: } # endblock body

@@ md.tx
: cascade base;
: override body -> {
<h1><: $path :></h1>
: $content | mark_raw
: } # endblock body

__END__

=head1 NAME

Plack::App::Directory::Markdown - Serve translated HTML from markdown files from document root with directory index

=head1 SYNOPSIS

  # app.psgi
  use Plack::App::Directory::Markdown;
  my $app = Plack::App::Directory::Markdown->new->to_app;

  # app.psgi(with options)
  use Plack::App::Directory::Markdown;
  my $app = Plack::App::Directory::Markdown->new({
    root           => '/path/to/markdown_files',
    title          => 'page title',
    tx_path        => '/path/to/xslate_templates',
    markdown_class => 'Text::Markdown',
  })->to_app;

=head1 DESCRIPTION

This is a PSGI application for documentation with markdown.

=head1 CONFIGURATION

=over 4

=item root

Document root directory. Defaults to the current directory.

=item title

Page title. Defaults to 'Markdown'.

=item tx_path

Text::Xslate's template directory. You can override default template with 'index.tx' and 'md.tx'.

=item markdown_class

Specify Markdown module. 'Text::Markdown' as default.
The module should have 'markdown' sub routine exportable.

=back


=head1 AUTHOR

Masayuki Matsuki E<lt>y.songmu@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
