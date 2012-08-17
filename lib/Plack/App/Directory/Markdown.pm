package Plack::App::Directory::Markdown;
use strict;
use warnings;
use utf8;
our $VERSION = '0.01';

use parent 'Plack::App::Directory';
use Plack::App::Directory::Markdown::Static;
use Plack::MIME;
use Encode qw/encode_utf8/;
use Data::Section::Simple;
use Text::Xslate;
use HTTP::Date;
use URI::Escape qw/uri_escape/;

use Plack::Util::Accessor;
Plack::Util::Accessor::mk_accessors(__PACKAGE__, qw(tx tx_path markdown_class markdown_ext));

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

sub markdown {
    my $self = shift;
    my $cls = $self->markdown_class || 'Text::Markdown';

    eval "use $cls qw/markdown/;";
    die $@ if $@;

    markdown(@_);
}

sub should_handle {
    my($self, $file) = @_;
    return -d $file || -f $file || $file =~ m!/_static/!;
}

sub locate_file {
    my($self, $env) = @_;

    my $path = $env->{PATH_INFO} || '';

    if ($path =~ /\0/) {
        return $self->return_400;
    }

    my $docroot = $self->root || ".";
    my @path = split '/', $path;
    if (@path) {
        shift @path if $path[0] eq '';
    } else {
        @path = ('.');
    }

    if (grep $_ eq '..', @path) {
        return $self->return_403;
    }

    my($file, @path_info);
    while (@path) {
        my $try = File::Spec::Unix->catfile($docroot, @path);
        if ($self->should_handle($try)) {
            $file = $try;
            last;
        } elsif (!$self->allow_path_info) {
            last;
        }
        unshift @path_info, pop @path;
    }

    if (!$file) {
        return $self->return_404;
    }

    if (!-r $file && $file !~ m!/_static/! ) {
        return $self->return_403;
    }

    return $file, join("/", "", @path_info);
}

sub serve_path {
    my($self, $env, $dir) = @_;

    if ($dir =~ m!/_static/!) {
        my $static_file = $dir;

        warn $self->root;
        my $root = $self->root || '';
        $root =~ s!^\./!!;
        $root =~ s!/$!!;
        $root = quotemeta $root;

        $static_file =~ s!$root/_static/!!;
        my $data = Plack::App::Directory::Markdown::Static::get_data($static_file);

        return [404, ['Content-Type' => 'text/plain'], ['NOT FOUND']] unless $data;

        my $mime_type = Plack::MIME->mime_type($static_file);
        return [ 200, [
            'Content-Type'   => $mime_type,
            'Content-Length' => length($data),
        ], [ $data ] ];
    }

    if (-f $dir) {
        if ($self->is_markdown($dir)) {
            my $content = do {local $/;open my $fh,'<:utf8',$dir or die $!;<$fh>};
            $content = $self->markdown($content);
            my $page = $self->tx->render('md.tx', {content => $content});
            $page = encode_utf8($page);

            my @stat = stat $dir;
            return [ 200, [
                'Content-Type'   => 'text/html; charset=utf-8',
                'Content-Length' => length($page),
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
    my $page  = $self->tx->render('index.tx', {files => \@files, path => $path});
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

1;

__DATA__

@@ base.tx
<!DOCTYPE html>
<html>
<head><title>MarkdownUp</title></head>
<style type="text/css">
</style>
<body>
<: block body -> { :>default body<: } :>
</body>
</html>

@@ index.tx
: cascade base;
: override body -> {
<h1><: $path :></h1>
<ul>
:   for $files -> $file {
<li><a href="<: $file.link :>"><: $file.name :></a>
:     if $file.mtime {
(<: $file.mtime :>)
:     }
</li>
:   }
</ul>
: } # endblock body

@@ md.tx
: cascade base;
: override body -> {
: $content | mark_raw
: } # endblock body

__END__

=head1 NAME

Plack::App::Directory::Markdown -

=head1 SYNOPSIS

  use Plack::App::Directory::Markdown;

=head1 DESCRIPTION

Plack::App::Directory::Markdown is

=head1 AUTHOR

Masayuki Matsuki E<lt>y.songmu@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
