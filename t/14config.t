# @(#)$Id: 14config.t 1139 2012-03-28 23:49:18Z pjf $

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.5.%d', q$Rev: 1139 $ =~ /\d+/gmx );
use File::Spec::Functions;
use FindBin qw( $Bin );
use lib catdir( $Bin, updir, q(lib) ), catdir( $Bin, q(lib) );

use English qw(-no_match_vars);
use Module::Build;
use Test::More;

BEGIN {
   my $current = eval { Module::Build->current };

   $current and $current->notes->{stop_tests}
            and plan skip_all => $current->notes->{stop_tests};
}

use Catalyst::Test q(MyApp);

my (undef, $context) = ctx_request( '' );

$context->stash( lang => q(de), newtag  => q(..New..) );

my $model = $context->model( q(Config) );

isa_ok( $model, 'MyApp::Model::Config' );

my $cfg = $model->load( q(default) );

ok( $cfg->{ '_vcs_default' } =~ m{ @\(\#\)\$Id: }mx,
    'Has reference element 1' );
ok( ref $cfg->{namespace}->{entrance}->{acl} eq q(ARRAY), 'Detects arrays' );

eval { $model->create_or_update }; my $e = $EVAL_ERROR; $EVAL_ERROR = undef;

ok( $e->as_string =~ m{ Result \s+ source \s+ not \s+ specified }msx,
    'Result source not specified' );

$model->keys_attr( q(an_element_name) );

eval { $model->create_or_update }; $e = $EVAL_ERROR; $EVAL_ERROR = undef;

ok( $e->as_string =~ m{ Result \s+ source \s+ an_element_name \s+ unknown }msx,
    'Result source an_element_name unknown' );

$model->keys_attr( q(globals) );

eval { $model->create_or_update }; $e = $EVAL_ERROR; $EVAL_ERROR = undef;

ok( $e->as_string =~ m{ File \s+ name \s+ not \s+ specified }msx,
    'File path not specified' );

my $file = q(default);

eval { $model->create_or_update( $file ) };

$e = $EVAL_ERROR; $EVAL_ERROR = undef;

ok( $e->as_string =~ m{ No \s+ element \s+ name \s+ specified }msx,
    'No element name specified' );

$model = $context->model( q(Config::Levels) );

isa_ok( $model, 'MyApp::Model::Config::Levels' );

my $args = {}; my $name;

eval { $name = $model->create_or_update( $file, q(dummy) ) };

$e = $EVAL_ERROR; $EVAL_ERROR = undef;

ok( !$e, 'Creates dummy level' );
ok( $name eq q(dummy), 'Returns element name on create' );

$cfg = $model->load( qw(default) );

my $acl = $cfg->{namespace}->{dummy}->{acl}->[0];

ok( $acl && $acl eq q(any), 'Dummy namespace defaults' );

eval { $model->create_or_update( $file, q(dummy) ) };

$e = $EVAL_ERROR; $EVAL_ERROR = undef;

ok( $e =~ m{ element \s+ dummy \s+ already \s+ exists }msx,
    'Detects existing record' );

eval { $model->delete( $file, $name ) };

$e = $EVAL_ERROR; $EVAL_ERROR = undef;

ok( !$e, 'Deletes dummy namespace' );

eval { $model->delete( $file, $name ) };

$e = $EVAL_ERROR; $EVAL_ERROR = undef;

ok( $e =~ m{ element \s+ dummy \s+ does \s+ not \s+ exist }msx,
    'Detects non existance on delete' );

my @res = $model->search( $file, { acl => q(@support) } );

ok( $res[0] && $res[0]->{name} eq q(admin), 'Can search' );

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
