package LinkRoller::Bundle;

use strict;
use base qw( MT::Category );

__PACKAGE__->install_properties({
    class_type => 'bundle',
});

sub class_label {
    return MT->translate("Bundle");
}

sub class_label_plural {
    MT->translate("Bundles");
}

sub basename_prefix {
    "bundle";
}

1;
