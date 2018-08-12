#!/usr/bin/perl

# PODNAME: tt2-play-area.psgi

use strict;
use warnings;

use Plack::Builder;
use TT2::Play::Area;

open my $rand, '<', '/dev/urandom' or die 'Failed to open /dev/urandom';
my $bytes = '0' x 32;
die "Failed to read sufficient from random - $!"
  unless sysread( $rand, $bytes, 32 ) == 32;
close $rand;
my $secret_key = unpack 'H*', $bytes;

builder {
    enable 'Session::Cookie',
      session_key => 'tt2-play-area',
      expires     => 12 * 3600,         # 12 hour
      secret      => $secret_key;
    enable 'CSRFBlock';

    TT2::Play::Area->to_app;
}

