package Plack::App::Directory::Markdown;
use strict;
use warnings;
use utf8;
our $VERSION = '0.01';

use parent 'Plack::App::Directory';

use Encode qw/encode_utf8/;
use Data::Section::Simple qw/get_data_section/;
use Text::Xslate;
use Text::Markdown::Discount qw/markdown/;
use HTTP::Date;
use URI::Escape;

# Stolen from rack/directory.rb
my $dir_file = "<tr><td class='name'><a href='%s'>%s</a></td><td class='size'>%s</td><td class='type'>%s</td><td class='mtime'>%s</td></tr>";
my $dir_page = <<PAGE;
<html><head>
  <title>%s</title>
  <meta http-equiv="content-type" content="text/html; charset=utf-8" />
  <style type='text/css'>
table { width:100%; }
.name { text-align:left; }
.size, .mtime { text-align:right; }
.type { width:11em; }
.mtime { width:15em; }
  </style>
</head><body>
<h1>%s</h1>
<hr />
<table>
  <tr>
    <th class='name'>Name</th>
    <th class='size'>Size</th>
    <th class='type'>Type</th>
    <th class='mtime'>Last Modified</th>
  </tr>
%s
</table>
<hr />
</body></html>
PAGE

my $tx = Text::Xslate->new(
    path => [
        Data::Section::Simple->new->get_data_section,
    ],
);

sub serve_path {
    my($self, $env, $dir) = @_;

    if (-f $dir) {
        if ($dir =~ /\.(?:markdown|mk?dn?)$/) {
            my $content = do {local $/;open my $fh,'<:utf8',$dir or die $!;<$fh>};
            $content = markdown($content);
            my $page = $tx->render('md.tx', {content => $content});
            $page = encode_utf8($page);

            my @stat = stat $dir;
            return [ 200, [
                'Content-Type'   => 'text/html; charset=utf-8',
                'Content-Length' => length($page),
                'Last-Modified'  => HTTP::Date::time2str( $stat[9] ),
            ], [ $page ] ];
        }
        else {
            return Plack::App::File::serve_path($self, $env, $dir);
        }
    }

    my $dir_url = $env->{SCRIPT_NAME} . $env->{PATH_INFO};

    if ($dir_url !~ m{/$}) {
        return $self->return_dir_redirect($env);
    }

    my @files = ([ "../", "Parent Directory", '', '', '' ]);

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
        my @stat = stat _;

        $url = join '/', map {uri_escape($_)} split m{/}, $url;

        if ($is_dir) {
            $basename .= "/";
            $url      .= "/";
        }

        my $mime_type = $is_dir ? 'directory' : ( Plack::MIME->mime_type($file) || 'text/plain' );
        push @files, [ $url, $basename, $stat[7], $mime_type, HTTP::Date::time2str($stat[9]) ];
    }

    my $path  = Plack::Util::encode_html("Index of $env->{PATH_INFO}");
    my $files = join "\n", map {
        my $f = $_;
        sprintf $dir_file, map Plack::Util::encode_html($_), @$f;
    } @files;
    my $page  = sprintf $dir_page, $path, $path, $files;

    return [ 200, ['Content-Type' => 'text/html; charset=utf-8'], [ $page ] ];
}


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

@@ md.tx
: cascade base;
: override body -> {
: $content | mark_raw
: } # endblock body

1;
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
