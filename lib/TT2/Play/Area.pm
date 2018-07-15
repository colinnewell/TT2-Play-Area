package TT2::Play::Area;

# ABSTRACT: Simple site to allow playing with TT2 syntax and built in plugins.

=head1 DESCRIPTION

This is a mini site for testing L<Template> Toolkit 2 and L<Template::Alloy>
rendering in a similar way to sites like jsFiddle.  It provides a pane for
editing the template, and a pane for providing the variables to pass it (in
JSON).

Currently supported 'engines' are,

=over

=item * Template (TT2)

=item * Template::Alloy

=item * Template::Alloy (using AUTO_FILTER html)

=back

On the front end jQuery and CodeMirror are used to provide the UI.

=head1 RUNNING 

The site is automatically built into a docker container on quay.io so if
you simply want to spin it up the quickest way is to,

    docker run -d -p5000:5000 quay.io/colinnewell/tt2-play-area:latest

This will expose it on port 5000 on localhost, so you should be able to
browse to L<http://localhost:5000>.

Alternatively, if you've installed the module from CPAN then you can run it
using plackup like this,

    plackup `which tt2-play-area.psgi`

Or if you checkout the github repo like this,

    cpanm --installdeps .
    plackup -I lib bin/tt2-play-area.psgi

=cut

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
    my $vars;
    eval {
        $vars = decode_json(body_parameters->{vars});
    };
    if($@) {
        send_as JSON => {
            result => 'Failed to parse variables: ' . $@,
        };
    }

    my $config = {};

    # create Template object
    my $template = Template->new($config);
    my $output;

    if ( ! $template->process( \$tt, $vars, \$output ) ){
        $output = 'Template error: ' . $template->error()->as_string;
    }

    send_as JSON => {
        result => $output,
    };
};

post '/alloy' => sub {
    process_alloy({});
};

post '/alloy_html' => sub {
    process_alloy({ AUTO_FILTER => 'html' });
};

sub process_alloy
{
    my $config = shift;
    my $tt   = body_parameters->{template};
    my $vars = decode_json(body_parameters->{vars});


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
