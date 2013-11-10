use strictures 1;

package GMVC::Controller;
use Object::Glib;

use namespace::clean;

property backend => (
    type => 'Object',
    required => 1,
    does => 'GMVC::Backend',
    handles => {
        quit => 'quit_main_loop',
    },
);

register;
