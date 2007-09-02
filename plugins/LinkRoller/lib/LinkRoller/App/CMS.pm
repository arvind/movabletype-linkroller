# Link Roller - A plugin for Movable Type.
# Copyright (c) 2005-2007, Arvind Satyanarayan.

package LinkRoller::App::CMS;

use strict;

sub view_link {
	my $app = shift;
	my $q = $app->param;
	my $plugin = plugin();
	
	my $blog = $app->blog;
	my $blog_id = $blog->id;
	my $id = $q->param('id');
	my $perms  = $app->permissions;
	my $author = $app->user;
	my $is_dialog = $q->param('is_dialog') || 0;
	
	my (%param, $link, @targets, @positions);
	
	require LinkRoller::Asset::Link;
	if($id) {
		$link = LinkRoller::Asset::Link->load($id);
		my $values = $link->column_values();
		%param = (%$values);
		
		my $meta_columns = LinkRoller::Asset::Link->properties->{meta_columns} || {};
	
		foreach my $col (keys %$meta_columns) {
			$param{$col} =
              defined $q->param($col) ? $q->param($col) : $link->$col();
		}
		
		my $tags = $link->tags;
	  	if(defined $tags) {
		        require MT::Tag;
		        my $tag_delim = chr($app->user->entry_prefs->{tag_delim});
		        $tags = MT::Tag->join($tag_delim, $link->tags);
		        $param{tags} = $tags;	
	  	}
	}
	
	## Now load user's preferences and customization for new/edit
    ## entry page.
    if ($perms) {
		my $link_prefs = $perms->link_prefs || 'hidden,name,url,description,tags|Bottom';
        my $pref_param = $app->load_entry_prefs( $link_prefs );
        %param = ( %param, %$pref_param );
        $param{disp_prefs_bar_colspan} = $param{new_object} ? 1 : 2;

        # Completion for tags
        my $auth_prefs = $author->entry_prefs;
        if ( my $delim = chr( $auth_prefs->{tag_delim} ) ) {
            if ( $delim eq ',' ) {
                $param{'auth_pref_tag_delim_comma'} = 1;
            }
            elsif ( $delim eq ' ' ) {
                $param{'auth_pref_tag_delim_space'} = 1;
            }
            else {
                $param{'auth_pref_tag_delim_other'} = 1;
            }
            $param{'auth_pref_tag_delim'} = $delim;
        }

        require MT::ObjectTag;
        my $count = MT::Tag->count(
            undef,
            {
                'join' => MT::ObjectTag->join_on(
                    'tag_id',
                    {
                        blog_id           => $blog_id,
                        object_datasource => LinkRoller::Asset::Link->datasource
                    },
                    { unique => 1 }
                )
            }
        );
        if ( $count > 1000 ) {    # FIXME: Configurable limit?
            $param{defer_tag_load} = 1;
        }
        else {
            require JSON;
            $param{tags_js} =
              JSON::objToJson(
                MT::Tag->cache( blog_id => $blog_id, class => 'LinkRoller::Asset::Link' )
              );
        }
    }
	
	$param{blog_id} ||= $blog->id;
	$param{saved} = $q->param('saved') || 0;
	
	push @{$param{targets}}, { target_name => $_ }
		foreach qw( _self _blank _parent _top );
		
	push @{$param{positions}}, { position_i => $_ }
		foreach (1..100);
		
	$app->add_breadcrumb($app->translate("Links"), 
		$app->uri('mode' => 'list_link', args => { $blog ? (blog_id => $blog->id) : () }));

	$app->add_breadcrumb($app->translate($id ? 'New Link' : 'Edit Link'));
	
	return $app->build_page($plugin->load_tmpl($is_dialog ? 'quickadd.tmpl' : 'edit_link.tmpl'), \%param);
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
	
	if($q->param('quickadd')){
	    my $ua = MT->new_ua;
	    my $req = HTTP::Request->new('GET', $q->param('url'));
	    my $result = $ua->request( $req );
	    $q->param('label', $result->title);
	    my $dat = $result->content;
			$dat =~ m!<\s*?meta\s*?name="description"\s*?content="(.*?)"\s*?/?\s*?>!i; 
		$q->param('description', $1);
		$dat =~ m!<\s*?meta\s*?name="(author|dc\.creator|dc\.publisher)"\s*?content="(.*?)"\s*?/?\s*?>!i;
		$q->param('blog_author', $2);
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

sub save_link_prefs {
    my $app   = shift;
    my $perms = $app->permissions
      or return $app->error( $app->translate("No permissions") );
    $app->validate_magic() or return;
    my $q     = $app->param;
    my $prefs = $app->_entry_prefs_from_params;
    $perms->link_prefs($prefs);
    $perms->save
      or return $app->error(
        $app->translate( "Saving permissions failed: [_1]", $perms->errstr ) );
    $app->send_http_header("text/json");
    return "true";
}

sub plugin { MT::Plugin::LinkRoller->instance; }

1;