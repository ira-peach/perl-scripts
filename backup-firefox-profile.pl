#!/usr/bin/env perl

# backup-firefox-profile.pl - backup firefox profiles on win32 from cygwin.
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

use File::Basename;
use File::Path qw(make_path);
use Getopt::Long qw(:config gnu_getopt no_ignore_case no_auto_abbrev);
use POSIX qw(strftime);

# cpan
use Config::IniFiles;
use String::ShellQuote;

my $now = time();
$now = strftime('%Y-%m-%d_%H%M%SZ', gmtime($now));

sub get_configured_profiles {
    my ($config_path) = @_;
    my @profile_paths = ();
    my $cfg = Config::IniFiles->new( -file => "$config_path/profiles.ini");
    for my $section (sort grep(/Profile[0-9]+/, $cfg->Sections)) {
        my $profile_path = $cfg->val($section, "Path");
        my $is_relative = $cfg->val($section, "IsRelative");
        $profile_path = "$config_path/$profile_path" if $is_relative;
        $profile_path = qx(cygpath '$profile_path');
        chomp $profile_path;
        push @profile_paths, $profile_path;
    }
    return @profile_paths;
}


my @args = ();
sub add_arg {
    push @args, @_;
}

my $backup_dir = ".";
my $dry_run = 0;
my $list = 0;
my $print = 0;
my $verbose = 0;

sub usage {
    my $prog = basename $0;
    say "usage: $prog [-hlcpnv] [-b BACKUP] [-- [TAR_ARGUMENTS]...]";
    say "  backup firefox profiles on win32 from cygwin";
    say "  -h,--help               display this usage";
    say "  -b,--backup-dir BACKUP  output backup files to BACKUP (default '.')";
    say "  -l,--list               list profiles and their paths";
    say "  -n,--dry-run            perform dry run with commands printed";
    say "  -p,--print              print Firefox configuration root";
    say "  -v,--verbose            be noisier";
}

GetOptions(
    "help|h" => sub { usage; exit 0 },
    "list|l" => \$list,
    "print|p" => \$print,
    "dry-run|n" => \$dry_run,
    "backup-dir|b=s" => \$backup_dir,
    "verbose|v!" => \$verbose,
    "<>" => \&add_arg)
or die "error in command line arguments\n";

die "use '--' to provide arguments to tar" if scalar @args;

push @args, @ARGV;

my $config_path = "";

my $uname = qx(uname);
if ($uname =~ /^CYGWIN_NT-/) {
    my $appdata = $ENV{APPDATA};
    die "error: no appdata environment variable present" unless $appdata;
    $appdata = qx(cygpath '$appdata');
    chomp $appdata;
    $config_path = "$appdata/Mozilla/Firefox";
}
else {
    die "Not implemented yet.";
}

die "error: config_path is blank for some reason" unless $config_path;
die "error: config_path at '$config_path' does not exist" unless -d $config_path;

if ($print) {
    say "$config_path";
    exit 0;
}

my @profile_paths = get_configured_profiles $config_path;

if ($list) {
    for my $profile_path (@profile_paths) {
        next unless -d $profile_path;
        print basename $profile_path;
        say ": $profile_path";
    }
}
else {
    if (not -d $backup_dir) {
        make_path $backup_dir or die "error: could not make '$backup_dir': $!\n";
    }

    for my $profile_path (@profile_paths) {
        next unless -d $profile_path;
        my $basename = basename $profile_path;
        my $backup_file = "$backup_dir/$now.$basename.tar.bz2";
        my @command = (
            "tar",
            "cjf",
            $backup_file,
            $profile_path,
            "$config_path/profiles.ini"
        );
        push @command, @args;
        my $command = shell_quote @command;
        if ($dry_run) {
            say "dry run: $command";
        }
        else {
            warn "backing up to '$backup_file'\n" if $verbose;
            system($command);
            if ($? == -1) {
                die "error: tar failed to execute: $!\n";
            }
            elsif ($? & 127) {
                my $signal = $? & 127;
                die "error: tar exited via signal $signal\n";
            }
            else {
                my $exit_status = $? >> 8;
                # override instances where archiving changed files is an error.
                $exit_status = 0 if $exit_status == 1;
                die "error: tar exited with non-zero exit status $exit_status\n" if $exit_status;
            }
        }
    }
}
