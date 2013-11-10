use strictures 1;

package GMVC::ViewBuilder;
use Object::Glib;
use curry::weak;
use Module::Runtime qw( use_module );
use Scalar::Util qw( weaken );
use GMVC::Objects qw(
    object
    object_connect
    object_connect_after
    call_method
);

use aliased 'GMVC::View';

use namespace::clean;

property config_file => (
    type => 'Object',
    is => 'rpo',
    required => 1,
    class => 'Path::Tiny',
);

property singleton => (
    type => 'Object',
    is => 'rpwp',
    class => 'GMVC::View',
    init_arg => undef,
    predicate => 1,
);

property model_manager => (
    type => 'Object',
    required => 1,
    class => 'GMVC::ModelManager',
    handles => {
        _get_model => 'get_model',
    },
);

property dispatch_callback => (
    is => 'rpo',
    required => 1,
);

my $_rx_ident = qr{
    [a-z_]
    [a-z0-9_]*
}xi;
my $_rx_action = qr{
    \A
    /
    ( $_rx_ident )
    /
    ( $_rx_ident )
    \z
}xi;

sub get_view {
    my ($self, $manager, %vars) = @_;
    return $self->_get_singleton
        if $self->_has_singleton;
    my $config = $manager->load_config(
        $self->_get_config_file,
        variables => {
            %vars,
        },
        functions => {
            path => sub { $manager->get_data_file(@_) },
            model => sub { $self->_get_model(@_) },
            view => sub { $manager->get_view(@_) },
            widget_builder => sub { $manager->get_cb_widget_builder(@_) },
            view_builder => sub { $manager->get_cb_view_builder(@_) },
            view_widget => sub { $manager->get_view_widget(@_) },
            view_root => sub { $manager->get_view_root_widget(@_) },
            call => \&call_method,
            require => sub {
                use_module($_)
                    for @_;
                return 1;
            },
            connect => sub {
                my ($object, $signal, $action) = @_;
                object_connect($object, { $signal => $action });
                return 1;
            },
            connect_after => sub {
                my ($object, $signal, $action) = @_;
                object_connect_after($object, { $signal => $action });
                return 1;
            },
            widget => sub {
                my ($class, $args) = @_;
                my ($connect, $connect_after, $child);
                if (ref $args eq 'HASH') {
                    my %all = %$args;
                    $connect = delete $all{connect};
                    $connect_after = delete $all{connect_after};
                    $child = delete $all{child};
                    $args = {%all};
                }
                my $widget = object($class, $args);
                $widget->add($child)
                    if defined $child;
                object_connect($widget, $connect)
                    if defined $connect;
                object_connect_after($widget, $connect_after)
                    if defined $connect_after;
                return $widget;
            },
            action => sub {
                my ($action, @args) = @_;
                $action =~ $_rx_action
                    or die "Invalid action path '$action'\n";
                my @all_args = ($1, $2, @args);
                my $dispatch = $self->_get_dispatch_callback;
                return sub { $dispatch->(@all_args, @_) };
            },
        },
    );
    my $is_singleton = delete $config->{singleton};
    my $view = View->new(widgets => $config);
    $self->_set_singleton($view)
        if $is_singleton;
    return $view;
}

register;
