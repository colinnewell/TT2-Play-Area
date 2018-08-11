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
use Crypt::Mac::HMAC 'hmac_b64u';
use Crypt::Misc qw/encode_b64u decode_b64u/;
use Dancer2;
use File::ShareDir 'dist_dir';
use Path::Tiny;
use String::Compare::ConstantTime 'equals';
use Template;
use Template::Alloy;

our $VERSION = '0.001';

my $example_dir = path( dist_dir('TT2-Play-Area') )->child('examples');

my %engines = (
    tt2        => 'TT2',
    alloy      => 'Template::Alloy',
    alloy_html => 'Template::Alloy + AUTO_FILTER = html',
);

get '/' => sub {
    my $template  = $example_dir->child('index.tt');
    my $vars_file = $example_dir->child('index.vars');
    my @files     = $example_dir->children(qr/\.settings/);
    my @examples;
    for my $file (@files) {
        my ( $name, $settings ) = load_settings($file);
        unless ( $name eq 'index' ) {
            push @examples, { name => $name, title => $settings->{title} };
        }
    }
    template 'index',
      {
        csrf_token  => gen_csrf_token(),
        engine_list => engine_list_for_ui( selected => ['tt2'] ),
        examples    => [ sort { lc $a->{title} cmp lc $b->{title} } @examples ],
        tt          => $template->slurp_utf8,
        variables   => $vars_file->slurp_utf8,
      };
};

get '/rand' => sub {
    return request->env->{KEY};

    #return $key;
};

sub engine_list_for_ui {
    my %args = @_;
    my %engine_list;
    %engine_list =
      map { $_ => { name => $engines{$_}, selected => 0 } } keys %engines;
    $engine_list{$_}{selected} = 1 for @{ $args{selected} };
    return \%engine_list;
}

post '/tt2' => sub {
    my $tt = body_parameters->{template};
    my $vars;
    my @engines = query_parameters->get_all('engine');
    eval { $vars = decode_json( body_parameters->{vars} ); };
    if ($@) {
        send_as JSON =>
          { result => { 'Error' => 'Failed to parse variables: ' . $@, } };
    }

    my $config = {};

    my %engine_output;
    for my $engine (@engines) {
        my $output;
        if ( $engine eq 'tt2' ) {

            # create Template object
            my $template = Template->new($config);

            if ( !$template->process( \$tt, $vars, \$output ) ) {
                $output = 'Template error: ' . $template->error()->as_string;
            }
        }
        elsif ( $engine eq 'alloy' ) {
            $output = process_alloy( {} );
        }
        elsif ( $engine eq 'alloy_html' ) {
            $output = process_alloy( { AUTO_FILTER => 'html' } );
        }
        $engine_output{ $engines{$engine} } = $output;
    }

    send_as JSON => { result => \%engine_output, };
};

get '/example/:name' => sub {
    my $name = route_parameters->get('name');
    return status 404 unless $name =~ /^[-\w]+$/;

    my $template  = $example_dir->child( $name . '.tt' );
    my $vars_file = $example_dir->child( $name . '.vars' );
    my $settings  = $example_dir->child( $name . '.settings' );
    unless ( $vars_file->exists && $template->exists ) {
        return status 404;
    }
    my $selected = ['tt2'];
    my $tt_vars  = {
        csrf_token => gen_csrf_token(),
        tt         => $template->slurp_utf8,
        variables  => $vars_file->slurp_utf8
    };
    if ( $settings->exists ) {
        my ( $name, $data ) = load_settings($settings);
        $tt_vars->{example_data} = $data;
        $tt_vars->{example_name} = $name;
        $selected = $data->{engines} if exists $data->{engines};
    }
    $tt_vars->{engine_list} = engine_list_for_ui( selected => $selected );
    template 'index', $tt_vars;
};

sub process_alloy {
    my $config = shift;
    my $tt     = body_parameters->{template};
    my $vars   = decode_json( body_parameters->{vars} );

    # create Template object
    my $template = Template::Alloy->new($config);
    my $output;
    unless ( $template->process( \$tt, $vars, \$output ) ) {
        $output = 'Template error:' . $template->error()->as_string;
    }

    return $output;
}

sub load_settings {
    my $file   = shift;
    my ($name) = $file->stringify =~ /(\w+)\.settings$/;
    my $data   = decode_json( $file->slurp_utf8 );
    return ( $name, $data );
}

sub gen_csrf_token {
    my $val = '0' x 32;
    die 'Unable to call getrandom' unless syscall 318, $val, 32, 0 == 32;
    return _create_csrf_token($val);
}

sub check_csrf_token {
    my $token = shift;
    my ($value) = split /:/, $token;
    my $expected = _create_csrf_token( decode_b64u($value) );
    return equals( $expected, $token );
}

sub _create_csrf_token {
    my $val = shift;
    return encode_b64u($val) . ':'
      . hmac_b64u( 'SHA256', request->env->{KEY}, $val );
}

1;
