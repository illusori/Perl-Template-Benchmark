#!perl -T

use strict;
use warnings;

use Test::More;

use Template::Benchmark;

my ( $bench, $plugin, $plugin_module, $template_dir, $cache_dir,
     $engine_errors );

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

$plugin_module = "Template::Benchmark::Engines::$plugin";

plan tests => 10 + 2;

#
#  1:  ensure Template::Benchmark detects that the engine is available.
is_deeply(
    [ grep { $_ eq $plugin_module } Template::Benchmark->engine_plugins() ],
    [ $plugin_module ],
    "is $plugin detected?" );

#
#  2-3: construct
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
#  4: no engine_errors
$engine_errors = $bench->engine_errors();
is_deeply( $engine_errors, {},
    'no engine errors produced' );
foreach my $engine ( keys( %{$engine_errors} ) )
{
    diag( "Engine error: $engine\n" .
        join( "\n", @{$engine_errors->{ $engine }} ) );
}

#
#  5: engines()
is_deeply( [ $bench->engines() ],
    [ $plugin_module ],
    '$bench->engines()' );

#
#  6: features()
{
    my %o = Template::Benchmark->default_options();
    is_deeply( [ $bench->features() ],
        [ grep { $o{ $_ } } Template::Benchmark->valid_features() ],
        '$bench->features()' );
}

#
#  7-8: template dir exists
$template_dir = $bench->{ template_dir };
isnt( $template_dir, undef, 'template_dir set' );
ok( -d $template_dir, 'template_dir exists' );

#
#  9-10: cache dir exists
$cache_dir = $bench->{ cache_dir };
isnt( $cache_dir, undef, 'cache_dir set' );
ok( -d $cache_dir, 'cache_dir exists' );




#
#  +2: Cleanup, dirs removed.
undef $bench;
ok( !( -d $template_dir ), 'template_dir removed' );
ok( !( -d $cache_dir ),    'cache_dir removed' );
