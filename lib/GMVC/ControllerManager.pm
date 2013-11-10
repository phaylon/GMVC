use strictures 1;

package GMVC::ControllerManager;
use Object::Glib;
use GMVC::Objects qw( object_direct call_method );
use Config::Rad;

use namespace::clean;

property config_file => (
    type => 'Object',
    is => 'rpo',
    required => 1,
    class => 'Path::Tiny',
);

property backend => (
    type => 'Object',
    is => 'rpo',
    required => 1,
    does => 'GMVC::Backend',
);

property model_manager => (
    type => 'Object',
    required => 1,
    class => 'GMVC::ModelManager',
    handles => {
        _get_model => 'get_model',
    },
);

property view_manager => (
    type => 'Object',
    required => 1,
    class => 'GMVC::ViewManager',
    handles => {
        _get_view => 'get_view',
        _get_view_builder => 'get_view_builder',
        _get_view_widget => 'get_view_widget',
        _get_cb_widget_builder => 'get_cb_widget_builder',
        _get_cb_view_builder => 'get_cb_view_builder',
    },
);

property config_functions => (
    type => 'Hash',
    required => 1,
    item_isa => sub {
        die "Not a code reference\n"
            unless ref $_[0] eq 'CODE';
    },
    handles => {
        _get_config_function_kv => 'all',
    },
);

property config_variables => (
    type => 'Hash',
    required => 1,
    handles => {
        _get_config_variable_kv => 'all',
    },
);

property controllers => (
    type => 'Hash',
    item_class => 'GMVC::Controller',
    lazy => 1,
    init_arg => undef,
    builder => sub {
        my ($self) = @_;
        my $rad = Config::Rad->new(
            functions => {
                model => sub { $self->_get_model(@_) },
                view => sub { $self->_get_view(@_) },
                widget_builder => sub {
                    return $self->_get_cb_widget_builder(@_);
                },
                view_builder => sub {
                    return $self->_get_cb_view_builder(@_);
                },
                view_widget => sub { $self->_get_view_widget(@_) },
                call => \&call_method,
                controller => sub {
                    return object_direct(@_[0, 1], {
                        backend => $self->_get_backend,
                    })
                },
                $self->_get_config_function_kv,
            },
            variables => {
                $self->_get_config_variable_kv,
            },
        );
        return $rad->parse_file($self->_get_config_file);
    },
    handles => {
        get_controller => 'get',
        has_controller => 'exists',
        run_all => ['each_value', sub {
            my ($controller, $method, @args) = @_;
            $controller->$method(@args)
                if $controller->can($method);
            return 1;
        }],
    },
);

sub dispatch_action {
    my ($self, $controller_id, $action_id, @args) = @_;
    die "Unknown controller '$controller_id'\n"
        unless $self->has_controller($controller_id);
    my $controller = $self->get_controller($controller_id);
    my $method = "on_${action_id}";
    return $controller->$method(@args);
}

register;
