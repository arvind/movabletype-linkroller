# Link Roller - A plugin for Movable Type.
# Copyright (c) 2005-2008, Arvind Satyanarayan.

package LinkRoller::Template::ContextHandlers;

use strict;

sub load_tags {
	my $tags = {
		block => {
			'Links' => \&_hdlr_links,
			'LinkIfTagged?' => sub { _hdlr_core_tag('_hdlr_asset_if_tagged', @_); },
			'LinkTags' => sub { _hdlr_core_tag('_hdlr_asset_tags', @_); },
			'LinkIsFirstInRow' => sub { _hdlr_core_tag('_hdlr_pass_tokens', @_); },
            'LinkIsLastInRow' => sub { _hdlr_core_tag('_hdlr_pass_tokens', @_); },
            'LinksHeader' => sub { _hdlr_core_tag('_hdlr_pass_tokens', @_); },
            'LinksFooter' => sub { _hdlr_core_tag('_hdlr_pass_tokens', @_); }
		},
		function => {
			'LinkID' => sub { _hdlr_core_tag('_hdlr_asset_id', @_); },
			'LinkName' => sub { _hdlr_core_tag('_hdlr_asset_label', @_); },
			'LinkURL' => sub { _hdlr_core_tag('_hdlr_asset_url', @_); },
			'LinkDescription' => \&_hdlr_link_description,
			'LinkAuthor' => sub { _hdlr_link_property('link_author', @_); },
			'LinkRel' => sub { _hdlr_link_property('rel', @_); },
			'LinkTarget' => sub { _hdlr_link_property('target', @_); },
			'LinkXFN' => sub { _hdlr_link_property('xfn', @_); },
			'LinkDateAdded' => sub { _hdlr_core_tag('_hdlr_asset_date_added', @_); },
			# 'LinkModifiedDate' => sub { _hdlr_core_tag('_hdlr_link_date_modified', @_); },
			'LinkAddedBy' => sub { _hdlr_core_tag('_hdlr_asset_added_by', @_); },
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