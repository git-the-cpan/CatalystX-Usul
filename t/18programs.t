# @(#)$Id: 18programs.t 1085 2011-11-29 22:26:06Z pjf $

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.4.%d', q$Rev: 1085 $ =~ /\d+/gmx );
use File::Spec::Functions;
use FindBin qw( $Bin );
use lib catdir( $Bin, updir, q(lib) );

use Module::Build;
use Test::More;

BEGIN {
   my $current = eval { Module::Build->current };

   $current and $current->notes->{stop_tests}
            and plan skip_all => $current->notes->{stop_tests};

   plan tests => 2;
}

use_ok q(CatalystX::Usul::Programs);

my $prog = CatalystX::Usul::Programs->new( {
   config  => { appldir   => File::Spec->curdir,
                localedir => catdir( qw(t locale) ) },
   homedir => q(t), n => 1 } );

my $meta = $prog->get_meta( q(META.yml) );

ok( $meta->name eq q(CatalystX-Usul), q(meta file class) );

unlink $prog->logfile;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
