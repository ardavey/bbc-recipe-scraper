#!/usr/bin/perl

use strict;
use warnings;
use 5.010;
use utf8;

use WWW::Mechanize;
use HTML::TreeBuilder;
use Data::Dumper;

binmode STDOUT, ":utf8";

my $base_url = 'http://www.bbc.co.uk';
my $mech = WWW::Mechanize->new();
my $tree = HTML::TreeBuilder->new();

my %recipes;
my %ingredients;

foreach my $letter ( "a".."z" ) {
  do {
    my $url = "$base_url/food/ingredients/by/letter/$letter";
    $mech->get( $url );
  } while ( $mech->status() != 200 );

  $tree->parse_content( $mech->content() );

  my @ingredients = $tree->look_down(
    _tag => 'li',
    class => 'resource food',
  );

  foreach my $ing ( @ingredients ) {
    my $links_ref = $ing->extract_links( 'a' );
    my $ing_link = $links_ref->[0][0];
    $ingredients{ $base_url.$ing_link }++;
  }
}

foreach my $ing ( sort keys %ingredients ) {
  do {
    eval { $mech->get( $ing ); }
  } while ( $mech->status() != 200 );

  my $url = $mech->find_link( text_regex => qr/^all recipes using/ );
  do {
    eval { $mech->get( $url ); }
  } while ( $mech->status != 200 );

  my $count = 1;

  PAGE: while ( 1 ) {
    my $tree = HTML::TreeBuilder->new_from_content( $mech->content );
    my ( $recipes_div ) = $tree->look_down(
      _tag => 'div',
      id => 'article-list',
    );
    
    if ( defined $recipes_div ) {
      foreach my $recipe ( @{ $recipes_div->extract_links( 'a' ) } ) {
        my $link = $recipe->[1];
        if ( $link->attr( 'href' ) =~ m!/food/recipes/! ) {
          $recipes{ $base_url.$link->attr( 'href' ) }++;
          if ( $recipes{ $base_url.$link->attr( 'href' ) } == 1 ) {
            say $link->as_text . ",$base_url" . $link->attr( 'href' );
          }
        }
      }
    }
    
    if ( $mech->find_link( text_regex => qr/^Next$/ ) ) {
      eval{ $mech->follow_link( text_regex => qr/^Next$/ ) };

      while ( $mech->status != 200 ) {
        $mech->back;
        eval{ $mech->follow_link( text_regex => qr/^Next$/ ) };
      }
      next PAGE;
    }
    else {
      last PAGE;
    }
  }
}
