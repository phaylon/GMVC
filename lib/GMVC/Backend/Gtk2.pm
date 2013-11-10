use strictures 1;

package GMVC::Backend::Gtk2;
use Object::Glib;

use namespace::clean;

sub run_main_loop {
    my ($self) = @_;
    Gtk2->main;
}

sub quit_main_loop {
    my ($self) = @_;
    Gtk2->main_quit;
}

sub load {
    my ($self) = @_;
    require Gtk2;
    Gtk2->init;
    return 1;
}

with 'GMVC::Backend';

register;
