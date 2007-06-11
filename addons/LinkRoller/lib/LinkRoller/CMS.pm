package LinkRoller::CMS;

use strict;

# This package simply holds code that is being grafted onto the CMS
# application; the namespace of the package is different, but the 'app'
# variable is going to be a MT::App::CMS object.

sub list_links {
    my $app = shift;
    $app->list_entries( { type => 'link' } );
}

1;