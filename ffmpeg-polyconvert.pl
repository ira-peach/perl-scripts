#!/usr/bin/env perl

# ffmpeg-polyconvert - try converting video many times for size reduction
# Copyright (C) 2024  Ira Peach
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

use v5.36.0;
use warnings;
use strict;

use Getopt::Long qw(:config gnu_getopt no_ignore_case no_auto_abbrev);

my $int = 32;
my $toggle = 0;

my @args = ();
sub add_arg {
    push @args, @_;
}

sub usage {
    use File::Basename;
    my $prog = basename $0;
    say "usage: $prog [OPTIONS] PATH";
    say "  Convert video at PATH to several possibilities for testing.";
    say "  -h,--help  display this usage";
}

GetOptions(
    "help|h" => sub { usage; exit 0 },
    "<>" => \&add_arg)
or die "error in command line arguments\n";

push @args, @ARGV;

die "Give only 1 argument for video file.\n" unless scalar @args == 1;

my $input_video = $args[0];

die "no such path exists: '$input_video'" unless -f $input_video;

my @crfs = 20..40;
my @codecs = ("libx264", "libx265");

my $filename = basename $input_video, ".mp4";

for my $codec (@codecs) {
    for my $crf (@crfs) {
        system qq(ffmpeg -i "$input_video" -vcodec "$codec" -crf "$crf" "$filename.$codec.$crf.mp4");
    }
}
