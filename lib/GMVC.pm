use strictures 1;

package GMVC;
use Object::Glib;
use Config::Rad;
use Module::Runtime qw( use_module );
use Path::Tiny;
use curry::weak;

use aliased 'GMVC::ModelManager';
use aliased 'GMVC::ViewManager';
use aliased 'GMVC::ControllerManager';

use namespace::clean;

our $VERSION = '0.000001'; # 0.0.1
$VERSION = eval $VERSION;

property config_functions => (
    type => 'Hash',
    is => 'rpo',
    lazy => 1,
    builder => sub { {} },
    item_isa => sub {
        die "Not a code reference\n"
            unless ref $_[0] eq 'CODE';
    },
);

property config_variables => (
    type => 'Hash',
    is => 'rpo',
    lazy => 1,
    builder => sub { {} },
);

property backend => (
    type => 'Object',
    is => 'rpo',
    does => 'GMVC::Backend',
    lazy => 1,
    coerce => sub {
        my ($value) = @_;
        return use_module(join '::', 'GMVC::Backend', $value)->new;
    },
    builder => sub {
        my ($self) = @_;
        return use_module('GMVC::Backend::Gtk2')->new;
    },
    handles => {
        _run_main_loop => 'run_main_loop',
        _load_backend => 'load',
    },
);

property config_dir => (
    type => 'Object',
    class => 'Path::Tiny',
    coerce => \&path,
    handles => {
        _get_model_config_file => ['child', 'models.conf'],
        _get_view_config_dir => ['child', 'view'],
        _get_controller_config_file => ['child', 'controllers.conf'],
    },
);

property model_manager => (
    type => 'Object',
    is => 'rpo',
    class => ModelManager,
    lazy => 1,
    init_arg => undef,
    builder => sub {
        my ($self, $class) = @_;
        return ModelManager->new(
            config_file => $self->_get_model_config_file,
            config_functions => $self->_get_config_functions,
            config_variables => $self->_get_config_variables,
        );
    },
);

property view_manager => (
    type => 'Object',
    is => 'rpo',
    class => ViewManager,
    lazy => 1,
    init_arg => undef,
    builder => sub {
        my ($self, $class) = @_;
        return ViewManager->new(
            model_manager => $self->_get_model_manager,
            config_dir => $self->_get_view_config_dir,
            dispatch_callback => $self->curry::weak::_dispatch_action,
            config_functions => $self->_get_config_functions,
            config_variables => $self->_get_config_variables,
        );
    },
);

property controller_manager => (
    type => 'Object',
    is => 'rpo',
    class => ControllerManager,
    lazy => 1,
    init_arg => undef,
    builder => sub {
        my ($self, $class) = @_;
        return ControllerManager->new(
            backend => $self->_get_backend,
            model_manager => $self->_get_model_manager,
            view_manager => $self->_get_view_manager,
            config_file => $self->_get_controller_config_file,
            config_functions => $self->_get_config_functions,
            config_variables => $self->_get_config_variables,
        );
    },
    handles => {
        _run_startup_methods => ['run_all', 'startup'],
        _run_shutdown_methods => ['run_all', 'shutdown'],
        _dispatch_action => 'dispatch_action',
    },
);

sub run {
    my ($self) = @_;
    $self->_load_backend;
    $self->_run_startup_methods;
    $self->_run_main_loop;
    $self->_run_shutdown_methods;
    return 1;
}

register;

=head1 NAME

GMVC - Description goes here

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

 Robert Sedlacek <rs@474.at>

=head1 CONTRIBUTORS

None yet - maybe this software is perfect! (ahahahahahahahahaha)

=head1 COPYRIGHT

Copyright (c) 2013 the GMVC L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.
