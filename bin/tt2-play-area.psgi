#!/usr/bin/perl

# PODNAME: tt2-play-area.psgi

use strict;
use warnings;

use Plack::Builder;
use TT2::Play::Area;

builder {
    TT2::Play::Area->to_app;
}

