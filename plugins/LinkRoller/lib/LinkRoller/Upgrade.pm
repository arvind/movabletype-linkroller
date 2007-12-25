# Link Roller - A plugin for Movable Type.
# Copyright (c) 2005-2008, Arvind Satyanarayan.

package LinkRoller::Upgrade;
use strict;

sub mt_blogroll {
	my $class = MT->model('asset.link');
	
	use Blogroll::Links;
	use Blogroll::Category;
	use Blogroll::Placement;
	use MT::Tag;

	my $iter = Blogroll::Links->load_iter();
	while (my $link = $iter->()) {
		my $names  = $link->column_names;
		
		my $asset = $class->new;
		$asset->class('link');
		$asset->url($link->uri);
		$asset->description($link->desc);
		$asset->label($link->name);	
		
		foreach my $col (@$names) {
			next unless $asset->can($col);			
			$asset->$col($link->$col);
		}
		
		# Migrated MT Blogroll's categories to tags
		my $tagstr = MT::Tag->join( ', ', $link->tags );
		my @cat_lbls; 
		
		my @places = Blogroll::Placement->load({ entry_id => $link->id });
		foreach my $place (@places) {
			my $cat = Blogroll::Category->load($place->category_id);
			next unless $cat;
			
			push @cat_lbls, lc $cat->label;
		}
		
		$tagstr = join ', ', $tagstr, @cat_lbls;
		my @tags = MT::Tag->split(', ', $tagstr);
		$asset->set_tags(@tags);
			
		$asset->save or die $asset->errstr;
	}
}

1;