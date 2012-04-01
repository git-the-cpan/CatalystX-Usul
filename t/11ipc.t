# @(#)$Id: 11ipc.t 1154 2012-04-01 12:11:52Z pjf $

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.5.%d', q$Rev: 1154 $ =~ /\d+/gmx );
use File::Spec::Functions qw( catdir catfile tmpdir updir );
use FindBin qw( $Bin );
use lib catdir( $Bin, updir, q(lib) );

use English qw( -no_match_vars );
use File::Basename;
use Module::Build;
use Test::More;

BEGIN {
   my $current = eval { Module::Build->current };

   $current and $current->notes->{stop_tests}
            and plan skip_all => $current->notes->{stop_tests};
}

use_ok q(CatalystX::Usul::Programs);

{  package Logger;

   sub new {
      return bless {}, q(Logger);
   }

   sub debug {
      my $self = shift; warn ''.(join ' ', @_)."\n";
   }
}

my $perl = $^X;
my $ref  = CatalystX::Usul::Programs->new( {
   config  => { appldir   => File::Spec->curdir,
                localedir => catdir( qw(t locale) ),
                tempdir   => q(t), },
   homedir => q(t),
   log     => Logger->new,
   n       => 1, } );
my $cmd  = "${perl} -e 'print \"Hello World\"'";

ok $ref->run_cmd( $cmd )->out eq q(Hello World), 'run_cmd system';

$cmd = "${perl} -e 'exit 1'";

eval { $ref->run_cmd( $cmd ) }; my $error = $EVAL_ERROR;

ok $error, 'run_cmd system unexpected rv';

ok ref $error eq $ref->exception_class, 'exception is right class';

ok $ref->run_cmd( $cmd, { expected_rv => 1 } ), 'run_cmd system expected rv';

$cmd = [ $perl, '-e', 'print "Hello World"' ];

ok $ref->run_cmd( $cmd )->out eq "Hello World", 'run_cmd IPC::Run';

eval { $ref->run_cmd( [ $perl, '-e', 'exit 1' ] ) };

ok $EVAL_ERROR, 'run_cmd IPC::Run unexpected rv';

ok $ref->run_cmd( [ $perl, '-e', 'exit 1' ], { expected_rv => 1 } ),
   'run_cmd IPC::Run expected rv';

eval { $ref->run_cmd( "unknown_command_xa23sd3", { debug => 1 } ) };

$error = $EVAL_ERROR; ok $error =~ m{ unknown_command }mx, 'unknown command';

my $path = catfile( $ref->tempdir, basename( $PROGRAM_NAME, q(.t) ).q(.log) );

-f $path and unlink $path;

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
