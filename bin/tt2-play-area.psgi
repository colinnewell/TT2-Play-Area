#!/usr/bin/perl

# PODNAME: tt2-play-area.psgi

use strict;
use warnings;

use Plack::Builder;
use TT2::Play::Area;

# FIXME: need to replace the secret key on load up.
builder {
    TT2::Play::Area->to_app;
}

