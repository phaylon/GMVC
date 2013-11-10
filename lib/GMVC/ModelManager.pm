use strictures 1;

package GMVC::ModelManager;
use Object::Glib;
use GMVC::Objects qw( object call_method );
use Config::Rad;

use namespace::clean;

property config_file => (
    type => 'Object',
    is => 'rpo',
    required => 1,
    class => 'Path::Tiny',
);

property config_variables => (
    type => 'Hash',
    required => 1,
    handles => {
        _get_config_variable_kv => 'all',
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

property models => (
    type => 'Hash',
    lazy => 1,
    init_arg => undef,
    builder => sub {
        my ($self) = @_;
        my $rad = Config::Rad->new(
            functions => {
                call => \&call_method,
                object => sub { object(@_) },
                $self->_get_config_function_kv,
            },
            variables => {
                $self->_get_config_variable_kv,
            },
        );
        return $rad->parse_file($self->_get_config_file);
    },
    handles => {
        get_model => 'get_required',
    },
);

register;
