#!/usr/bin/env perl

# install.pl - install the perl-scripts programs to a common user PATH directory.
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

# This program will install to ~/bin.  You should add this to your PATH to use
# these programs.  You may also use -p PREFIX to change the prefix from ~/bin.
#
# This re-creates the age-old functionality of installations for programs, and
# probably shouldn't be copied.
#
# Requires the `install` program to be present.  Testing with cygwin.

use v5.36.0;
use warnings;
use strict;

use File::Basename;
use Getopt::Long qw(:config gnu_getopt no_ignore_case no_auto_abbrev);

# The below imports require installation of some packages.  Packages are listed
# for cygwin, then debian.

# perl-JSON-XS, libjson-xs-perl
#use JSON::XS qw(decode_json encode_json);

# perl-File-Slurp, libfile-slurp-perl
#use File::Slurp qw(read_file write_file);

# perl-YAML-LibYAML, libyaml-libyaml-perl
#use YAML::XS qw(Dump Load);

sub usage {
    my $prog = basename $0;
    say "usage: $prog [OPTIONS]... PATH [OPTIONAL_STUFF]...";
    say "  install the perl-scripts programs to a common user PATH directory";
    say "  -h,--help     display this usage and exit";
    say "  -p,--prefix   change prefix to install to (default ~/bin)";
    say "  -v,--verbose  write extra messaging (default)";
    say "  --no-verbose  don't write extra messaging";
}

my @args = ();
sub add_arg {
    push @args, @_;
}

my $dry_run = 0;
my $prefix = "~/bin";
my $verbose = 1;

GetOptions(
    "help|h" => sub { usage; exit 0 },
    "dry-run|n!" => \$dry_run,
    "prefix|p=s" => \$prefix,
    "verbose|v!" => \$verbose,
    "<>" => \&add_arg)
or die "error in command line arguments\n";

push @args, @ARGV;

die "no arguments allowed" if scalar @args > 0;

my $scriptdir = dirname($0);

$prefix = glob($prefix);
warn "Installing scripts to '$prefix'\n" if $verbose;

sub install {
    my ($file) = @_;
    my $source = "$scriptdir/$file";
    my $destination = "$prefix/$file";

    if ($dry_run) {
        say "would install '$source' to '$destination'";
    }
    else {
        warn "'$source' -> '$destination'\n" if $verbose;
        system(qq(install -m 755 "$source" "$destination"));
        my $exit_status = $? >> 8;
        die "install failed.\n" if $exit_status;
    }
}

install ",yt-dlp";
install "backup-firefox-profile.pl";
install "ffmpeg-polyconvert.pl";
install "flux-kubectl";
install "new-pl";
install "sillytavern";
