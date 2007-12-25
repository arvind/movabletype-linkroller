# Link Roller - A plugin for Movable Type.
# Copyright (c) 2005-2008, Arvind Satyanarayan.

package LinkRoller::Import;
use strict;

use base qw(MT::ErrorHandler);

sub get_param {
    my $class = shift;
    my ($blog_id) = @_;

    my $param = { blog_id => $blog_id };
    $param;
}

sub import_contents {
    my $class = shift;
    my (%param) = @_;
    my $iter = $param{Iter};
    my $blog = $param{Blog} or return $class->error(MT->translate("No Blog"));
    my $cb = $param{Callback} || sub { };
    my $encoding = $param{Encoding};
	
    if (exists $param{ImportAs}) {
    } elsif (exists $param{ParentAuthor}) {
        require MT::Auth;
        return $class->error(MT->translate(
            "The OPML Importer only supports importing links as yourself"));
    } else {
        return $class->error(MT->translate(
            "Need either ImportAs or ParentAuthor"));
    }
    $cb->("\n");
    my $import_result = eval {
        while (my $stream = $iter->()) {
            my $result = eval {
                $class->start_import($cb, $stream, %param);
            };
            $cb->($@) unless $result;
        }
        $class->errstr ? undef : 1;
    };
    $import_result;
} 

sub start_import {
    my $self = shift;
    my ($cb, $stream, %param) = @_;

    my $xml = do { local $/ = undef; <$stream>} || ''; 
	$xml =~ s|\x0d|\x0a|g;
    $xml =~ s|\x0a+|\x0a|g;
    $xml =~ s|([^>])\x0a|$1 |g;
    my $items;
	my $class = MT->model('asset.link');
	
    eval { $items = _get_items($xml); };
    my $e = $@ if $@;
    if ($e) {
        $param{Callback}->($e);
        return $self->error($e);
    }

	foreach my $item (@$items) {
		my $url = $item->{html} || $item->{xml};
		next unless $url;
		
		my $link = $class->new;
		$link->set_values({
			class => 'link',
			blog_id => $param{Blog}->id,
			created_by => $param{ImportAs}->id,
			label => $item->{text},
			description => $item->{desc},
			url => $url
		});
		$link->save or die $link->errstr;		
	}
    1;
}

# Code from an ancient version of MT-Outliner by Chad Everret 

sub _get_items {
    my ( $dat ) = @_;
    my ( $folder, $folder_open, $skipfirst ) = ( '', 0, 0 );
    my ( @content, @items );
    
    @content = split ( /\x0a/, $dat );
    foreach my $content ( @content ) {
        my $use_item = 0;
        my $item = {};
        $content =~ s|^[\s]*||;
        next unless ( $content =~ m|^<[/]?outline| );
        if ( $folder eq 'Unfiled' ) {
            if ( $content =~ m|^<outline text="(.*)">| || $content =~ m|^<outline title="(.*)">| ) {
                if ( $skipfirst ) {
                    $skipfirst = 0;
                    next;
                }
                $folder_open++;
                } elsif ( $content =~ m|^</outline>| ) {
                $folder_open-- unless ( $folder_open == 0 );
                } else {
                $use_item = 1 if ( !$folder_open );
            }
            } else {
            if ( $content =~ m|^<outline text="$folder">| || $content =~ m|^<outline title="$folder">| ) {
                $folder_open = 1;
                } elsif ( $content =~ m|^</outline>| ) {
                $folder_open = 0;
                } else {
                $use_item = 1 if ( $folder_open || !$folder );
            }
        }
        if ( $use_item ) {
            ( $item->{text} ) = ( $content =~ m|text="([^"]*)"| );
            ( $item->{text} ) = ( $content =~ m|title="([^"]*)"| ) unless $item->{text};
            ( $item->{desc} ) = ( $content =~ m|description="([^"]*)"| );
            ( $item->{desc} ) =~ s|>|>|g if ( $item->{desc} );
            ( $item->{desc} ) =~ s|<|<|g if ( $item->{desc} );
            ( $item->{desc} ) =~ s|"|"|g if ( $item->{desc} );
            ( $item->{html} ) = ( $content =~ m|htmlUrl="(http://[^\s]*)[\s]?"| );
            ( $item->{html} ) = ( $content =~ m|url="(http://[^\s]*)[\s]?"| ) unless $item->{html};
            ( $item->{xml} ) = ( $content =~ m|xmlUrl="(http://[^\s]*)[\s]?"| );
            push ( @items, $item );
        }
    }
    my $items = \@items;
    $items;
}


1;