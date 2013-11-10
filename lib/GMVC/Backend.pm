use strictures 1;

package GMVC::Backend;
use Object::Glib::Role;

use namespace::clean;

requires qw(
    run_main_loop
    quit_main_loop
);

1;
