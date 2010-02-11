#!perl -T

use strict;
use warnings;

use Test::More;

use File::Spec;
use FindBin;
use Cwd ();

plan tests => 3;

my ( $script_dir, $script, $output );

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


ok( ( -e $script ), 'benchmark_template_engines found' );

ok( ( -x $script ), 'benchmark_template_engines is executable' );

$output = `$script --nofeatures --featurematrix`;
like( $output, qr/^--- (Engine errors|Feature Matrix)/,
    'script compiles ok' );
