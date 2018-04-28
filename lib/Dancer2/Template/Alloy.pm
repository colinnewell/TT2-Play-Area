# ABSTRACT: Template::Alloy engine for Dancer2

package Dancer2::Template::Alloy;

use Moo;
use Template::Alloy;
use Scalar::Util;
use Dancer2::Core::Types 'InstanceOf';

extends 'Dancer2::Template::TemplateToolkit';

has '+engine' => ( isa => InstanceOf ['Template::Alloy'] );

sub _build_engine {
    my $self      = shift;
    my $charset   = $self->charset;
    my %tt_config = (
        ANYCASE  => 1,
        RELATIVE => 1,
        AUTO_FILTER => 'html',
        length($charset) ? ( ENCODING => $charset ) : (),
        %{ $self->config },
    );

    my $start_tag = $self->config->{'start_tag'};
    my $stop_tag = $self->config->{'stop_tag'} || $self->config->{end_tag};
    $tt_config{'START_TAG'} = $start_tag
      if defined $start_tag && $start_tag ne '[%';
    $tt_config{'END_TAG'} = $stop_tag
      if defined $stop_tag && $stop_tag ne '%]';

    Scalar::Util::weaken( my $ttt = $self );
    my $include_path = $self->config->{include_path};
    $tt_config{'INCLUDE_PATH'} ||= sub {
        [ $ttt->views, ( defined $include_path ? $include_path : () ), ];
    };

    my $tt = Template::Alloy->new(%tt_config);
    $Template::Stash::PRIVATE = undef
      if $self->config->{show_private_variables};
    return $tt;
}

1;
