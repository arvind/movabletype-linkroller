# Link Roller - A plugin for Movable Type.
# Copyright (c) 2005-2007, Arvind Satyanarayan.

package LinkRoller::Asset::Link;

use strict;
use base qw( MT::Asset );

__PACKAGE__->install_properties( { class_type => 'link', } );
__PACKAGE__->install_meta( { columns => [ 'target', 'rel', 'blog_author', 'visible', 'updated' ] } );

sub class_label {
    MT->translate('Link');
}

sub class_label_plural {
    MT->translate('Links');
}

sub has_thumbnail { 0; }


1;
