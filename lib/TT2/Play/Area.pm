package TT2::Play::Area;

# ABSTRACT: Simple site to allow playing with TT2 syntax and built in plugins.

use strictures 2;
use Dancer2;

our $VERSION = '0.001';

get '/' => sub {
    template 'index';
};

1;
