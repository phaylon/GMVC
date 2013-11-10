use strictures 1;

package GMVC::ViewManager;
use Object::Glib;
use Scalar::Util qw( weaken );

use aliased 'GMVC::ViewBuilder';

use namespace::clean;

property config_dir => (
    type => 'Object',
    is => 'rpo',
    required => 1,
    class => 'Path::Tiny',
    handles => {
        _get_config_file => 'child',
        get_data_file => ['child', 'data'],
    },
);

property config_loader => (
    type => 'Object',
    is => 'rpo',
    init_arg => undef,
    lazy => 1,
    builder => sub {
        my ($self) = @_;
        return Config::Rad->new(
            cache => 1,
            include_paths => [$self->_get_config_dir],
            functions => {
                $self->_get_config_function_kv,
            },
            variables => {
                $self->_get_config_variable_kv,
            },
        );
    },
    handles => {
        load_config => 'parse_file',
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

property model_manager => (
    type => 'Object',
    is => 'rpo',
    required => 1,
    class => 'GMVC::ModelManager',
);

property dispatch_callback => (
    is => 'rpo',
    required => 1,
);

property view_builders => (
    type => 'Hash',
    init_arg => undef,
    item_class => ViewBuilder,
    handles => {
        get_view_builder => ['get_buildable', sub {
            my ($self, $id) = @_;
            return ViewBuilder->new(
                config_file => $self->_get_config_file("$id.conf"),
                dispatch_callback => $self->_get_dispatch_callback,
                model_manager => $self->_get_model_manager,
            );
        }],
    },
);

sub get_cb_view_builder {
    my ($self, $id) = @_;
    my $wmanager = $self;
    weaken $wmanager;
    my $builder = $wmanager->get_view_builder($id);
    return sub {
        return $builder->get_view($wmanager, @_);
    };
}

sub get_cb_widget_builder {
    my ($self, $id, $widget) = @_;
    my $builder = $self->get_view_builder($id);
    $widget = 'root'
        unless defined $widget;
    my $wmanager = $self;
    weaken $wmanager;
    return sub {
        return $builder->get_view($wmanager, @_)->get_widget($widget);
    };
}

sub get_view {
    my ($self, $id, %vars) = @_;
    my $builder = $self->get_view_builder($id);
    return $builder->get_view($self, %vars);
}

sub get_view_widget {
    my ($self, $id, $widget, %vars) = @_;
    my $view = $self->get_view($id, %vars);
    $widget = 'root'
        unless defined $widget;
    return $view->get_widget($widget);
}

register;
