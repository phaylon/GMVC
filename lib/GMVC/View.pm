use strictures 1;

package GMVC::View;
use Object::Glib;

use namespace::clean;

property widgets => (
    type => 'Hash',
    required => 1,
    handles => {
        get_widget => 'get_required',
        get_root => ['get_required', 'root'],
    },
);

sub widget_connect {
    my ($self, $name, @args) = @_;
    return $self->get_widget($name)->signal_connect(@args);
}

sub widget_connect_after {
    my ($self, $name, @args) = @_;
    return $self->get_widget($name)->signal_connect_after(@args);
}

sub widget_set {
    my ($self, $name, @args) = @_;
    return $self->get_widget($name)->set_property(@args);
}

sub widget_get {
    my ($self, $name, @args) = @_;
    return $self->get_widget($name)->get_property(@args);
}

register;
