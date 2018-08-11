#!/usr/bin/perl

# PODNAME: tt2-play-area.psgi

use strict;
use warnings;

use Plack::Builder;
use TT2::Play::Area;

# 32 byte key needed
my $key = '0' x 32;

# SYS_getrandom
# echo -e "#include <sys/syscall.h>\nSYS_getrandom" | gcc -E -
die 'Unable to call getrandom' unless syscall 318, $key, 32, 0 == 32;
builder {
    enable sub {
        my $app = shift;
        sub {
            my $env = shift;
            $env->{KEY} = $key;
            $app->($env);
        };
    };
    TT2::Play::Area->to_app;
}

