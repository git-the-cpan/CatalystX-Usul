#!/usr/bin/perl

# @(#)$Id: 20uri_for.t 421 2009-03-31 09:22:07Z pjf $

use strict;
use warnings;
use File::Spec::Functions;
use FindBin  qw( $Bin );
use lib (catdir( $Bin, updir, q(lib) ));
use Test::More;
use URI;

BEGIN {
#   if ($ENV{AUTOMATED_TESTING} || $ENV{PERL_CR_SMOKER_CURRENT}
#       || ($ENV{PERL5OPT} || q()) =~ m{ CPAN-Reporter }mx
#       || ($ENV{PERL5_CPANPLUS_IS_RUNNING} && $ENV{PERL5_CPAN_IS_RUNNING})) {
#      plan skip_all => q(CPAN Testing stopped);
#   }

   plan tests => 7;
}

{
   package MyApp;

   use Catalyst qw(ConfigComponents);

   __PACKAGE__->config
      ( action_class       => q(CatalystX::Usul::Action),
        "Controller::Root" => {
           base_class      => q(CatalystX::Usul::Controller::Root),
           namespace       => q() } );

   __PACKAGE__->setup;
}

$ENV{REMOTE_ADDR} = '127.0.0.1';
$ENV{SERVER_NAME} = 'localhost';
$ENV{SERVER_PORT} = '80';

my $context = MyApp->prepare;

$context->dispatcher( MyApp->dispatcher );
$context->request( Catalyst::Request->new( {
   base => URI->new( q(http://127.0.0.1/) ) } ) );

my $controller = $context->controller( q(Root) );

isa_ok( $controller, q(MyApp::Controller::Root) );

$controller->messages( { eNoFile => { text => 'File [_1] not found' } } );

my $msg = $controller->loc( q(eNoFile), q(dummy) );

chomp $msg; ok( $msg eq 'File dummy not found', q(Localize) );

ok( $controller->uri_for( $context ) eq q(http://127.0.0.1/),
    q(Uri for redirect to default) );

ok( $controller->uri_for( $context, q(), q(en) ) eq q(http://127.0.0.1/en),
    q(Uri for root controller) );

ok( $controller->uri_for( $context, q(root/about), q(en) )
    eq q(http://127.0.0.1/en/about), q(Uri for about) );

my @args = ( qw(en a b) );

ok( $controller->uri_for( $context, q(root/room_closed), @args )
    eq q(http://127.0.0.1/en/room_closed/a/b), q(Uri with some args) );

push @args, { key1 => q(value1) };

ok( $controller->uri_for( $context, q(root/room_closed), @args )
    eq q(http://127.0.0.1/en/room_closed/a/b?key1=value1),
    q(Uri with some params) );
