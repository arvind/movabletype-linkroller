# Link Roller - A plugin for Movable Type.
# Copyright (c) 2005-2007, Arvind Satyanarayan.

package MT::Plugin::LinkRoller;

use 5.006;    # requires Perl 5.6.x
use MT 4.0;   # requires MT 4.0 or later

use base 'MT::Plugin';
our $VERSION = '2.6a1';
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
					'create:link' => {
						label      => "Link",
			            order      => 201,
			            mode       => 'view_link',
			            permission => 'manage_pages',
			            view       => "blog",
					}
				},
				methods => {
					'view_link' => '$LinkRoller::LinkRoller::App::CMS::view_link',
					'save_link' => '$LinkRoller::LinkRoller::App::CMS::save_link',
					'save_link_prefs' => '$LinkRoller::LinkRoller::App::CMS::save_link_prefs'
				}
			}
		}
	});
}

1;