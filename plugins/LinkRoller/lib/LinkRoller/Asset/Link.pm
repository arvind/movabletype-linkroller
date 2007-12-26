# Link Roller - A plugin for Movable Type.
# Copyright (c) 2005-2008, Arvind Satyanarayan.

package LinkRoller::Asset::Link;

use strict;
use base qw( MT::Asset );
use MT::Util qw( encode_html );

__PACKAGE__->install_properties( { class_type => 'link', } );
__PACKAGE__->install_meta( { columns => [ 'target', 'rel', 'link_author', 'hidden', 'updated', 'position' ] } );

sub class_label {
    MT->translate('Link');
}

sub class_label_plural {
    MT->translate('Links');
}

sub has_thumbnail { 0; }

sub as_html {
    my $asset   = shift;
    my ($param) = @_;
    my $text = sprintf(
                        '<a href="%s" title="%s" target="%s" rel="%s">%s</a>',
                        encode_html( $asset->url ),
						encode_html( $asset->description ),
						encode_html( $asset->target ),
						encode_html( $asset->rel ),
                        encode_html( $asset->label )
                        );

	return $asset->enclose($text);
}


1;
