# @(#)$Id: 23time.t 1144 2012-03-29 21:52:22Z pjf $

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.5.%d', q$Rev: 1144 $ =~ /\d+/gmx );
use File::Spec::Functions;
use FindBin qw( $Bin );
use lib catdir( $Bin, updir, q(lib) );

use Class::Null;
use Exception::Class ( q(TestException) => { fields => [ qw(arg1 arg2) ] } );
use English qw( -no_match_vars );
use Module::Build;
use Test::More;

BEGIN {
   my $current = eval { Module::Build->current };

   $current and $current->notes->{stop_tests}
            and plan skip_all => $current->notes->{stop_tests};

   plan tests => 9;
}

use CatalystX::Usul::Time qw(str2date_time str2time time2str);

ok( time2str( undef, 0 ) eq q(1970-01-01 01:00:00), q(stamp) );

my $dt = q().str2date_time( q(11/9/2007 14:12) );

ok( $dt eq q(2007-09-11T13:12:00), q(str2date_time) );

$dt ne q(2007-09-11T13:12:00) and warn "str2date_time is ${dt}\n";

ok( str2time( q(2007-07-30 01:05:32), q(BST) )
    eq q(1185753932), q(str2time/1) );

my $tm = str2time( q(30/7/2007 01:05:32), q(BST) );

ok( $tm eq q(1185753932), q(str2time/2) );

$tm ne q(1185753932) and warn "str2time/2 is ${tm}\n";

ok( str2time( q(30/7/2007), q(BST) ) eq q(1185750000),
    q(str2time/3) );

ok( str2time( q(2007.07.30), q(BST) ) eq q(1185750000),
    q(str2time/4) );

ok( str2time( q(1970/01/01), q(GMT) ) eq q(0), q(str2time/epoch) );

ok( time2str( q(%Y-%m-%d), 0 ) eq q(1970-01-01), q(time2str/1) );

ok( time2str( q(%Y-%m-%d %H:%M:%S), 1185753932 )
    eq q(2007-07-30 01:05:32), q(time2str/2) );

# Local Variables:
# mode: perl
# tab-width: 3
# End:
