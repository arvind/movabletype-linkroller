# Link Roller - A plugin for Movable Type.
# Copyright (c) 2005-2008, Arvind Satyanarayan.

package LinkRoller::Template::ContextHandlers;

use strict;

sub load_tags {
	my $tags = {
		block => {
			'RolledLinks' => \&_hdlr_links,
			'RolledLinkIfTagged?' => sub { _hdlr_core_tag('_hdlr_asset_if_tagged', @_); },
			'RolledLinkTags' => sub { _hdlr_core_tag('_hdlr_asset_tags', @_); },
			'RolledLinkIsFirstInRow' => sub { _hdlr_core_tag('_hdlr_pass_tokens', @_); },
            'RolledLinkIsLastInRow' => sub { _hdlr_core_tag('_hdlr_pass_tokens', @_); },
            'RolledLinksHeader' => sub { _hdlr_core_tag('_hdlr_pass_tokens', @_); },
            'RolledLinksFooter' => sub { _hdlr_core_tag('_hdlr_pass_tokens', @_); }
		},
		function => {
			'RolledLinkID' => sub { _hdlr_core_tag('_hdlr_asset_id', @_); },
			'RolledLinkName' => sub { _hdlr_core_tag('_hdlr_asset_label', @_); },
			'RolledLinkURL' => sub { _hdlr_core_tag('_hdlr_asset_url', @_); },
			'RolledLinkDescription' => \&_hdlr_link_description,
			'RolledLinkAuthor' => sub { _hdlr_link_property('link_author', @_); },
			'RolledLinkRel' => sub { _hdlr_link_property('rel', @_); },
			'RolledLinkTarget' => sub { _hdlr_link_property('target', @_); },
			'RolledLinkXFN' => sub { _hdlr_link_property('xfn', @_); },
			'RolledLinkDateAdded' => sub { _hdlr_core_tag('_hdlr_asset_date_added', @_); },
			# 'RolledLinkModifiedDate' => sub { _hdlr_core_tag('_hdlr_link_date_modified', @_); },
			'RolledLinkAddedBy' => sub { _hdlr_core_tag('_hdlr_asset_added_by', @_); },
		}
	};
	return $tags;
}

sub _hdlr_core_tag {
	my $tag = shift;
	my $class = 'MT::Template::Context';
    eval "require $class;";
    if ($@) { die $@; $@ = undef; return 1; }
    my $method_ref = $class->can($tag);
    return $method_ref->(@_) if $method_ref;
    die MT->translate("Failed to find [_1]::[_2]", $class, $tag);	
	
}

sub _hdlr_links {
	my($ctx, $args, $cond) = @_;
	$args->{type} = 'link';
	
	require MT::Template::Context;
	return MT::Template::Context::_hdlr_assets($ctx, $args, $cond);
}

sub _hdlr_link_description {
    my $a = $_[0]->stash('asset')
        or return $_[0]->_no_asset_error('MTLinkDescription');

	$a->description;
}

sub _hdlr_link_property {
	my $property = shift;
	my ($ctx, $args) = @_;
	$args->{property} = $property;
	
	require MT::Template::Context;
	return MT::Template::Context::_hdlr_asset_property($ctx, $args);
}

1;