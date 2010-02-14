#!perl -T

use strict;
use warnings;

use Test::More;
use Test::Command;

use File::Spec;
use FindBin;
use Config;
use Cwd ();

plan tests => 4;

my ( $script_dir, $perl, $script, $script_options, $cmd, $tc );

{
    my ( @candidate_dirs );

    foreach my $startdir ( Cwd::cwd(), $FindBin::Bin )
    {
        push @candidate_dirs,
            File::Spec->catdir( $startdir, '..', 'script' ),
            File::Spec->catdir( $startdir, 'script' );
    }

    @candidate_dirs = grep { -d $_ } @candidate_dirs;

    plan skip_all => ( 'unable to find script dir relative to bin: ' .
        $FindBin::Bin . ' or cwd: ' . Cwd::cwd() )
        unless @candidate_dirs;

    $script_dir = $candidate_dirs[ 0 ];
}

$script = File::Spec->catfile( $script_dir, 'benchmark_template_engines' );

#  Untaint stuff so -T doesn't complain.
delete @ENV{qw(PATH IFS CDPATH ENV BASH_ENV)};   # Make %ENV safer
#  We trust their Cwd info and so forth.
$script =~ /^(.*)$/;
$script = $1;
#  Ditto their perl location.
$^X =~ /^(.*)$/;
$perl   = $1;

ok( ( -e $script ), 'benchmark_template_engines found' );
ok( ( -x $script ), 'benchmark_template_engines is executable' );


 #  Some smoke-test setups seem to set @INC so subcommands can't see
 #  where they've installed the required modules.
local $ENV{ PERL5LIB } = join( $Config{ path_sep } || ':', @INC );
diag( "Settinng PERL5LIB: $ENV{PERL5LIB}" );

$cmd = "$perl -c $script";
diag( "Testing script compiles with command: $cmd" );
$tc = Test::Command->new( cmd => $cmd );
$tc->run();
$tc->stderr_like( qr/syntax OK$/, 'script compiles ok' );

$cmd = "$perl $script --nofeatures --featurematrix";
diag( "Testing script output with command: $cmd" );
$tc = Test::Command->new( cmd => $cmd );
$tc->stdout_like( qr/^--- (Engine errors|Feature Matrix)/, 'command runs ok' );
