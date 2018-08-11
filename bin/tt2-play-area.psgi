#!/usr/bin/perl

# PODNAME: tt2-play-area.psgi

use strict;
use warnings;

use Plack::Builder;
use TT2::Play::Area;

builder {
    enable 'Session';
    enable 'CSRFBlock';
    TT2::Play::Area->to_app;
}

