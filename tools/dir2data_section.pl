#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use autodie;

use Path::Class qw/file dir/;
use Getopt::Long;
use Pod::Usage;
use MIME::Base64;

=head1 DESCRIPTION

    convert script dir to perl data section.

=head1 SYNOPSIS

    % dir2data_section.pl --dir=dir

=cut

my %args;
GetOptions(
    \%args,
    'dir=s',
) or die pod2usage(2);
pod2usage(1) if $args{help};


my $base_dir = $args{dir};
my @data_sections;

my $walker;
$walker = sub {
    my $dir = shift;
    for my $entry ($dir->children) {
        if (-d $entry) {
            $walker->($entry);
        }
        else {
            push @data_sections, data_section_single($entry, $base_dir);
        }
    }
};
$walker->(dir $base_dir);


sub data_section_single {
    my ($file, $base_dir) = @_;

    my $data_section = '@@ '. $file->relative($base_dir) ."\n";
    my $content = $file->slurp;
    if (is_binary($file)) {
        $content = encode_base64($content);
    }
    $data_section .= $content;
}

sub is_binary {
    my $file = shift;
    my ($ext) = $file =~ /\.([^.]+)$/;
    $ext = lc $ext;

    $ext && grep {$ext eq $_} qw/jpg png gif swf ico/;
}

print join "\n\n", @data_sections;


