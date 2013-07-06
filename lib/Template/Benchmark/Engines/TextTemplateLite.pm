package Template::Benchmark::Engines::TextTemplateLite;
# ABSTRACT: Template::Benchmark plugin for Text::TemplateLite.

use warnings;
use strict;

use base qw/Template::Benchmark::Engine/;

use Text::TemplateLite;
use Text::TemplateLite::Standard;

use File::Spec;
use File::Slurp;

our $VERSION = '1.09_02';

our %feature_syntaxes = (
    literal_text              =>
        join( "\n", ( join( ' ', ( 'foo' ) x 12 ) ) x 5 ),
    scalar_variable           =>
        '<<$scalar_variable>>',
    hash_variable_value       =>
        undef,
    array_variable_value      =>
        undef,
    deep_data_structure_value =>
        undef,
    array_loop_value          =>
        # Can loop but can't dereference arrays.
        undef,
    hash_loop_value           =>
        undef,
    records_loop_value        =>
        undef,
    array_loop_template       =>
        undef,
    hash_loop_template        =>
        undef,
    records_loop_template     =>
        undef,
    constant_if_literal       =>
        "<<??(1, 'true')>>",
    variable_if_literal       =>
        "<<??(\$variable_if, 'true')>>",
    constant_if_else_literal  =>
        "<<??(1, 'true', 'false')>>",
    variable_if_else_literal  =>
        "<<??(\$variable_if_else, 'true', 'false')>>",
    constant_if_template      =>
        # Probably sort of possible with tpl() somehow
        undef,
    variable_if_template      =>
        # Probably sort of possible with tpl() somehow
        undef,
    constant_if_else_template =>
        # Probably sort of possible with tpl() somehow
        undef,
    variable_if_else_template =>
        # Probably sort of possible with tpl() somehow
        undef,
    constant_expression       =>
        '<<+(10, 12)>>',
    variable_expression       =>
        '<<*($variable_expression_a, $variable_expression_b)>>',
    complex_variable_expression =>
        '<</(-(+(*($variable_expression_a, $variable_expression_b), ' .
        '$variable_expression_a), $variable_expression_b), ' .
        '$variable_expression_b)>>',
    constant_function         =>
        q{<<substr('this has a substring.', 11, 9)>>},
    variable_function         =>
        '<<substr($variable_function_arg, 4, 2)>>',
    );

sub syntax_type { return( 'mini-language' ); }
sub pure_perl { return( 1 ); }

sub benchmark_descriptions
{
    return( {
        TeTeLite =>
            "Text::TemplateLite ($Text::TemplateLite::VERSION)",
        } );
}

sub benchmark_functions_for_uncached_string
{
    my ( $self ) = @_;

    return( {
        TeTeLite =>
            sub
            {
                my $t = Text::TemplateLite->new();
                Text::TemplateLite::Standard::register( $t, ':all' );
                $t->set( $_[ 0 ] )
                  ->render( { %{$_[ 1 ]}, %{$_[ 2 ]} } )
                  ->result();
            },
        } );
}

sub benchmark_functions_for_uncached_disk
{
    my ( $self, $template_dir ) = @_;

    return( undef );
}

sub benchmark_functions_for_disk_cache
{
    my ( $self, $template_dir, $cache_dir ) = @_;

    return( undef );
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
    my ( $t );

    return( {
        TeTeLite =>
            sub
            {
                unless( $t )
                {
                    #  Store the renderer rather than the template. Renders twice
                    #  on first pass, but that's just for the comparison check not the
                    #  benchmark iterations.
                    $t = Text::TemplateLite->new(),
                    Text::TemplateLite::Standard::register( $t, ':all' );
                    $t = $t->set( scalar read_file( File::Spec->catfile( $template_dir, $_[ 0 ] ) ) )
                      ->render( { %{$_[ 1 ]}, %{$_[ 2 ]} } );
                }
                \$t->render( { %{$_[ 1 ]}, %{$_[ 2 ]} } )->result();
            },
        } );
}

1;

__END__

=pod

=head1 NAME

Template::Benchmark::Engines::TextTemplateLite - Template::Benchmark plugin for Text::TemplateLite.

=head1 VERSION

version 1.09_02

=head1 SYNOPSIS

Provides benchmark functions and template feature syntaxes to allow
L<Template::Benchmark> to benchmark the L<Text::TemplateLite> template
engine.

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-benchmark at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Benchmark>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Benchmark::Engines::TextTemplateLite

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
