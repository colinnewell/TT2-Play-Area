package TT2::Play::Area;

# ABSTRACT: Simple site to allow playing with TT2 syntax and built in plugins.

use strictures 2;
use Cpanel::JSON::XS;
use Dancer2;
use Template;
use Template::Alloy;

our $VERSION = '0.001';

get '/' => sub {
    template 'index';
};

post '/tt2' => sub {
    my $tt   = body_parameters->{template};
    my $vars = decode_json(body_parameters->{vars});

    my $config = {};

    # create Template object
    my $template = Template->new($config);
    my $output;
    $template->process( \$tt, $vars, \$output )
      || die $template->error();

    send_as JSON => {
        result   => $output,
    };
};

post '/alloy' => sub {
    my $tt   = body_parameters->{template};
    my $vars = decode_json(body_parameters->{vars});

    my $config = {};

    # create Template object
    my $template = Template::Alloy->new($config);
    my $output;
    $template->process( \$tt, $vars, \$output )
      || die $template->error();

    send_as JSON => {
        result   => $output,
    };
};

1;
