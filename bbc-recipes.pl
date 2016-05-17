#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

use WWW::Mechanize;
use HTML::TreeBuilder;
use Data::Dumper;

my $base_url = 'http://www.bbc.co.uk';
my $mech = WWW::Mechanize->new();

my %recipes;
my %ingredients;

foreach my $letter ( "a".."z" ) {
#foreach my $letter ( "a" ) {
  say "Letter ".uc( $letter );

  do {
    my $url = "$base_url/food/ingredients/by/letter/$letter";
    say "Fetching $url";
    $mech->get( $url );
  } while ( $mech->status() != 200 );

  my $tree = HTML::TreeBuilder->new();
  $tree->parse_content( $mech->content() );

  my @ingredients = $tree->look_down(
    _tag => 'li',
    class => 'resource food',
  );

  say "Found ".scalar(@ingredients)." ingredients";
  
  foreach my $ing ( @ingredients ) {
    my $links_ref = $ing->extract_links( 'a' );
    my $ing_link = $links_ref->[0][0];
    $ingredients{ "$base_url$ing_link" }++;
  }
}

say "Total: ".scalar( keys %ingredients )." ingredients";

say "Fetching recipes for ingredients...";

#print Dumper( \%ingredients );
