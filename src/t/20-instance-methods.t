#!perl -T

use strict;
use warnings;

use Test::More;

use Template::Benchmark;

my ( $bench, $plugin, $template_dir, $cache_dir );

eval "use Template::Sandbox";
if( $@ )
{
    eval "use Template::Toolkit";
    if( $@ )
    {
        eval "use HTML::Template";
        plan skip_all =>
            ( "Template::Sandbox, Template::Toolkit or HTML::Template " .
              "required for instance testing" )
            if $@;
        $plugin = 'HTMLTemplate';
    }
    else
    {
        $plugin = 'TemplateToolkit';
    }
}
else
{
    $plugin = 'TemplateSandbox';
}
diag( "Using plugin $plugin for tests" );

plan tests => 9 + 2;

#
#  1-2: construct
$bench = Template::Benchmark->new(
    only_plugin => $plugin,
    duration    => 1,
    repeats     => 1,
    );
isnt( $bench, undef,
    'constructor produced something' );
is( ref( $bench ), 'Template::Benchmark',
    'constructor produced a Template::Benchmark' );

#
#  3: engines()
is_deeply( [ $bench->engines() ],
    [ "Template::Benchmark::Engines::$plugin" ],
    '$bench->engines()' );

#
#  4: features()
{
    my %o = Template::Benchmark->default_options();
    is_deeply( [ $bench->features() ],
        [ grep { $o{ $_ } } Template::Benchmark->valid_features() ],
        '$bench->features()' );
}

#
#  5: engine_errors()
is_deeply( $bench->engine_errors(), {},
    'no engine errors' );

#
#  6-7: template dir exists
$template_dir = $bench->{ template_dir };
isnt( $template_dir, undef, 'template_dir set' );
ok( -d $template_dir, 'template_dir exists' );

#
#  8-9: cache dir exists
$cache_dir = $bench->{ cache_dir };
isnt( $cache_dir, undef, 'cache_dir set' );
ok( -d $cache_dir, 'cache_dir exists' );




#
#  +2: Cleanup, dirs removed.
undef $bench;
ok( !( -d $template_dir ), 'template_dir removed' );
ok( !( -d $cache_dir ),    'cache_dir removed' );
