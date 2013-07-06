package Template::Benchmark::Engines::TextXslateHT;
# ABSTRACT: Template::Benchmark plugin for Text::Xslate::Syntax::HTMLTemplate.

use warnings;
use strict;

use base qw/Template::Benchmark::Engine/;

use Text::Xslate;
use Text::Xslate::Syntax::HTMLTemplate;

our $VERSION = '1.09_02';

our %feature_syntaxes = (
    literal_text              =>
        join( "\n", ( join( ' ', ( 'foo' ) x 12 ) ) x 5 ),
    scalar_variable           =>
        '<TMPL_VAR NAME=scalar_variable>',
    hash_variable_value       =>
        undef,
    array_variable_value      =>
        undef,
    deep_data_structure_value =>
        undef,
    array_loop_value          =>
        undef,
    hash_loop_value           =>
        undef,
    records_loop_value        =>
        '<TMPL_LOOP NAME=records_loop><TMPL_VAR NAME=name>: ' .
        '<TMPL_VAR NAME=age></TMPL_LOOP>',
    array_loop_template       =>
        undef,
    hash_loop_template        =>
        undef,
    records_loop_template     =>
        '<TMPL_LOOP NAME=records_loop><TMPL_VAR NAME=name>: ' .
        '<TMPL_VAR NAME=age></TMPL_LOOP>',
    constant_if_literal       =>
        '<TMPL_IF EXPR="1">true</TMPL_IF>',
    variable_if_literal       =>
        '<TMPL_IF NAME=variable_if>true</TMPL_IF>',
    constant_if_else_literal  =>
        '<TMPL_IF EXPR="1">true<TMPL_ELSE>false</TMPL_IF>',
    variable_if_else_literal  =>
        '<TMPL_IF NAME=variable_if_else>true<TMPL_ELSE>false</TMPL_IF>',
    constant_if_template      =>
        '<TMPL_IF EXPR="1"><TMPL_VAR NAME=template_if_true></TMPL_IF>',
    variable_if_template      =>
        '<TMPL_IF NAME=variable_if><TMPL_VAR NAME=template_if_true></TMPL_IF>',
    constant_if_else_template =>
        '<TMPL_IF EXPR="1"><TMPL_VAR NAME=template_if_true>' .
        '<TMPL_ELSE><TMPL_VAR NAME=template_if_false></TMPL_IF>',
    variable_if_else_template =>
        '<TMPL_IF NAME=variable_if_else><TMPL_VAR NAME=template_if_true>' .
        '<TMPL_ELSE><TMPL_VAR NAME=template_if_false></TMPL_IF>',
    constant_expression       =>
        '<TMPL_VAR EXPR="10 + 12">',
    variable_expression       =>
        '<TMPL_VAR EXPR="variable_expression_a * variable_expression_b">',
    complex_variable_expression =>
        '<TMPL_VAR EXPR="' .
        '( ( variable_expression_a * variable_expression_b ) + ' .
        'variable_expression_a - variable_expression_b ) / ' .
        'variable_expression_b">',
    constant_function         =>
        q{<TMPL_VAR EXPR="substr( 'this has a substring', 11, 9 )">},
    variable_function         =>
        '<TMPL_VAR EXPR="substr( variable_function_arg, 4, 2 )">',
    );

sub syntax_type { return( 'mini-language' ); }
sub pure_perl
{
    return( 1 ) if $ENV{ XSLATE } and $ENV{ XSLATE } =~ / \b pp \b /xms;
    return( 0 );
}

sub benchmark_descriptions
{
    if( __PACKAGE__->pure_perl() )
    {
        return( {
            TeXsHTPP    =>
                "Text::Xslate::PP ($Text::Xslate::PP::VERSION) " .
                "with Text::Xslate::Syntax::HTMLTemplate ($Text::Xslate::Syntax::HTMLTemplate::VERSION)",
            } );
    }
    return( {
        TeXsHT    =>
            "Text::Xslate ($Text::Xslate::VERSION) " .
            "with Text::Xslate::Syntax::HTMLTemplate ($Text::Xslate::Syntax::HTMLTemplate::VERSION)",
        } );
}

sub benchmark_functions_for_uncached_string
{
    my ( $self ) = @_;

    return( {
        ( __PACKAGE__->pure_perl() ? 'TeXsHTPP' : 'TeXsHT' ) =>
            sub
            {
                my $t = Text::Xslate->new(
                    syntax   => 'HTMLTemplate',
                    compiler => 'Text::Xslate::Compiler::HTMLTemplate',
                    function => {
                        __choise_global_var__ =>
                            \&Text::Xslate::Syntax::HTMLTemplate::default_choise_global_var,
                        __has_value__ =>
                            \&Text::Xslate::Syntax::HTMLTemplate::default_has_value,
                        substr => sub { substr( $_[ 0 ], $_[ 1 ], $_[ 2 ] ) },
                        },
                    cache    => 0,
                    );
                \$t->render_string( $_[ 0 ], { %{$_[ 1 ]}, %{$_[ 2 ]} } );
            },
        } );
}

sub benchmark_functions_for_uncached_disk
{
    my ( $self, $template_dir ) = @_;
    my ( @template_dirs );

    @template_dirs = ( $template_dir );

    return( {
        ( __PACKAGE__->pure_perl() ? 'TeXsHTPP' : 'TeXsHT' ) =>
            sub
            {
                my $t = Text::Xslate->new(
                    syntax   => 'HTMLTemplate',
                    compiler => 'Text::Xslate::Compiler::HTMLTemplate',
                    function => {
                        __choise_global_var__ =>
                            \&Text::Xslate::Syntax::HTMLTemplate::default_choise_global_var,
                        __has_value__ =>
                            \&Text::Xslate::Syntax::HTMLTemplate::default_has_value,
                        substr => sub { substr( $_[ 0 ], $_[ 1 ], $_[ 2 ] ) },
                        },
                    path     => \@template_dirs,
                    cache    => 0,
                    );
                \$t->render( $_[ 0 ], { %{$_[ 1 ]}, %{$_[ 2 ]} } );
            },
        } );
}

sub benchmark_functions_for_disk_cache
{
    my ( $self, $template_dir, $cache_dir ) = @_;
    my ( @template_dirs );

    @template_dirs = ( $template_dir );

    return( {
        ( __PACKAGE__->pure_perl() ? 'TeXsHTPP' : 'TeXsHT' ) =>
            sub
            {
                my $t = Text::Xslate->new(
                    syntax   => 'HTMLTemplate',
                    compiler => 'Text::Xslate::Compiler::HTMLTemplate',
                    function => {
                        __choise_global_var__ =>
                            \&Text::Xslate::Syntax::HTMLTemplate::default_choise_global_var,
                        __has_value__ =>
                            \&Text::Xslate::Syntax::HTMLTemplate::default_has_value,
                        substr => sub { substr( $_[ 0 ], $_[ 1 ], $_[ 2 ] ) },
                        },
                    path      => \@template_dirs,
                    cache_dir => $cache_dir,
                    cache     => 2,
                    );
                \$t->render( $_[ 0 ], { %{$_[ 1 ]}, %{$_[ 2 ]} } );
            },
        } );
}

sub benchmark_functions_for_shared_memory_cache
{
    my ( $self, $template_dir, $cache_dir ) = @_;

    return( undef );
}

sub benchmark_functions_for_memory_cache
{
    my ( $self, $template_dir, $cache_dir ) = @_;

    return( undef );
}

sub benchmark_functions_for_instance_reuse
{
    my ( $self, $template_dir, $cache_dir ) = @_;
    my ( @template_dirs, $t );

    @template_dirs = ( $template_dir );

    return( {
        ( __PACKAGE__->pure_perl() ? 'TeXsHTPP' : 'TeXsHT' ) =>
            sub
            {
                $t = Text::Xslate->new(
                    syntax   => 'HTMLTemplate',
                    compiler => 'Text::Xslate::Compiler::HTMLTemplate',
                    function => {
                        __choise_global_var__ =>
                            \&Text::Xslate::Syntax::HTMLTemplate::default_choise_global_var,
                        __has_value__ =>
                            \&Text::Xslate::Syntax::HTMLTemplate::default_has_value,
                        substr => sub { substr( $_[ 0 ], $_[ 1 ], $_[ 2 ] ) },
                        },
                    path      => \@template_dirs,
                    cache_dir => $cache_dir,
                    cache     => 2,
                    ) unless $t;
                \$t->render( $_[ 0 ], { %{$_[ 1 ]}, %{$_[ 2 ]} } );
            },
        } );
}

1;

__END__

=pod

=head1 NAME

Template::Benchmark::Engines::TextXslateHT - Template::Benchmark plugin for Text::Xslate::Syntax::HTMLTemplate.

=head1 VERSION

version 1.09_02

=head1 SYNOPSIS

Provides benchmark functions and template feature syntaxes to allow
L<Template::Benchmark> to benchmark the L<Text::Xslate::Syntax::HTMLTemplate> template
engine.

=head1 KNOWN ISSUES AND BUGS

L<Text::Xslate::Syntax::HTMLTemplate> clashes with the L<HTML::Template> and L<HTML::Template::Pro> modules in some manner and will error when attempting to run templates if those engines are also being benchmarked.

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-benchmark at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Benchmark>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Benchmark::Engines::TextXslateHT

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Benchmark>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-Benchmark>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Template-Benchmark>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-Benchmark/>

=back

=head1 AUTHOR

Sam Graham <libtemplate-benchmark-perl BLAHBLAH illusori.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010-2011 by Sam Graham <libtemplate-benchmark-perl BLAHBLAH illusori.co.uk>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
