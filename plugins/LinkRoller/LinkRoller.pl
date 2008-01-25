# Link Roller - A plugin for Movable Type.
# Copyright (c) 2005-2008, Arvind Satyanarayan.

package MT::Plugin::LinkRoller;
use LinkRoller::Import;
use MT 4.1;   # requires MT 4.1 or later

use base 'MT::Plugin';
our $VERSION = '2.6';
our $SCHEMA_VERSION = '2.3001';

my $plugin;
MT->add_plugin($plugin = __PACKAGE__->new({
	name            => 'Link Roller',
	version         => $VERSION,
	description     => '<__trans phrase="At its heart, a powerful link manager">',
	author_name     => 'Arvind Satyanarayan',
	author_link     => 'http://www.movalog.com/',
	plugin_link     => 'http://plugins.movalog.com/link-roller/',
	doc_link        => 'http://plugins.movalog.com/link-roller/install/',
	schema_version  => $SCHEMA_VERSION
}));

# Allows external access to plugin object: MT::Plugin::LinkRoller->instance
sub instance { $plugin; }

sub init_registry {
	my $plugin = shift;
	$plugin->registry({
		object_types => {
			'asset.link' => 'LinkRoller::Asset::Link',
			'permission' => {
				'link_prefs' => 'string(255)'
			}
		},
		permissions => {
			'blog.manage_links' => {
				label => 'Manage Links',
				group => 'blog_upload',
				order => 301
			}
		},
		applications => {
			cms => {
				menus => {
					'create:link'  => {
						label      => "Link",
						order      => 201,
						dialog     => 'quickadd_link&is_dialog=1',
						args       => { 'is_dialog' => 1 },
						view       => "blog",
						permission => 'manage_pages'			            
					}
				},
				methods => {
					'quickadd_link'   => '$LinkRoller::LinkRoller::App::CMS::quickadd_link',
					'save_link'       => '$LinkRoller::LinkRoller::App::CMS::save_link',
					'save_link_prefs' => '$LinkRoller::LinkRoller::App::CMS::save_link_prefs'
				}
			}
		},
		callbacks => { # Rather than adding view_link method, just add transformer calls to switch screens when link
			'MT::App::CMS::template_source.edit_asset'  => '$LinkRoller::LinkRoller::App::CMS::edit_asset_src',
			'MT::App::CMS::template_param.edit_asset'   => '$LinkRoller::LinkRoller::App::CMS::edit_asset_param',
			'MT::App::CMS::template_source.asset_table' => '$LinkRoller::LinkRoller::App::CMS::asset_table_src' 
		},
		import_formats => {
			'import_opml' => {
				label   => 'Import OPML',
				type    => 'LinkRoller::Import',
				handler => 'LinkRoller::Import::import_contents',
				options_param => 'LinkRoller::Import::get_param',
			}
		},
		upgrade_functions => {
			'mt_blogroll' => {
				version_limit => $SCHEMA_VERSION, # Because this plugin doesn't share the same sig
				condition     => sub { eval "require Blogroll::Links"; $@ ? 0 : 1; },
				code          => '$LinkRoller::LinkRoller::Upgrade::mt_blogroll'
			}
		},
		tags => \&load_tags
	});
}

# A fix for when a schema_version number doesn't exist within the database
# Thank you Kevin Shay! <http://tech.groups.yahoo.com/group/mt-dev/message/1582>
{
	my $cfg = MT->config;
	my $plugin_schema = $cfg->PluginSchemaVersion || {};
	if (!$plugin_schema->{'LinkRoller/LinkRoller.pl'}) {
		$plugin_schema->{'LinkRoller/LinkRoller.pl'} = -1;
		$cfg->PluginSchemaVersion($plugin_schema, 1);
	}
}

sub load_tags {
	require LinkRoller::Template::ContextHandlers;
	return LinkRoller::Template::ContextHandlers::load_tags();
}

1;