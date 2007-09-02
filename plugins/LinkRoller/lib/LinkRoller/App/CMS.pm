# Link Roller - A plugin for Movable Type.
# Copyright (c) 2005-2007, Arvind Satyanarayan.

package LinkRoller::App::CMS;

use strict;

sub view_link {
	my $app = shift;
	my $q = $app->param;
	my $plugin = plugin();
	
	my $blog = $app->blog;
	my $id = $q->param('id');
	
	my ($param, $link, @targets, @positions);
	
	require LinkRoller::Asset::Link;
	if($id) {
		$link = LinkRoller::Asset::Link->load($id);
		$param = $link->column_values();
		
		my $meta_columns = LinkRoller::Asset::Link->properties->{meta_columns} || {};
	
		foreach my $col (keys %$meta_columns) {
			$param->{$col} = $link->$col();
		}
		
		my $tags = $link->tags;
	  	if(defined $tags) {
		        require MT::Tag;
		        my $tag_delim = chr($app->user->entry_prefs->{tag_delim});
		        $tags = MT::Tag->join($tag_delim, $link->tags);
		        $param->{tags} = $tags;	
	  	}
	}
	
	$param->{blog_id} ||= $blog->id;
	$param->{saved} = $q->param('saved') || 0;
	
	eval { MT::Plugin::CustomFields->instance; };
	$param->{customfields} = 1 unless $@;
	
	push @{$param->{targets}}, { target_name => $_ }
		foreach qw( _self _blank _parent _top );
		
	push @{$param->{positions}}, { position_i => $_ }
		foreach (1..100);
		
	$app->add_breadcrumb($app->translate("Links"), 
		$app->uri('mode' => 'list_link', args => { $blog ? (blog_id => $blog->id) : () }));

	$app->add_breadcrumb($app->translate($id ? 'New Link' : 'Edit Link'));
	
	return $app->build_page($plugin->load_tmpl('edit_link.tmpl'), $param);
}

sub save_link {
	my $app = shift;
	my $q = $app->param;
	
	my $blog_id = $q->param('blog_id');
	my $id = $q->param('id');
	
	my ($link);
	
	require LinkRoller::Asset::Link;
	if($id) {
		$link = LinkRoller::Asset::Link->load($id);
	} else {
		$link = LinkRoller::Asset::Link->new;
	}
		
	my $names  = $link->column_names;
    my %values = map { $_ => ( scalar $q->param($_) ) } @$names;
	my $meta_columns = LinkRoller::Asset::Link->properties->{meta_columns} || {};

	foreach my $col (keys %$meta_columns) {
		$values{$col} = $q->param($col);
	}
	
	$values{hidden} = 0
      if !defined( $values{hidden} )
      || $app->param('hidden') eq '';

	foreach my $col (keys %values) {
		$link->$col($values{$col});
	}
	
	my $tags = $q->param('tags');
  	if(defined $tags) {
	        require MT::Tag;
	        my $tag_delim = chr($app->user->entry_prefs->{tag_delim});
	        my @tags = MT::Tag->split($tag_delim, $tags);
	        $link->set_tags(@tags);	
  	}
	$link->class('link');
	$link->save or die $link->errstr;
	
	$app->add_return_arg( id => $link->id )
		if !$id;
	$app->call_return( saved => 1 );
}

sub plugin { MT::Plugin::LinkRoller->instance; }

1;