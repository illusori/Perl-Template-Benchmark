package Template::Benchmark::Engines::TextMiniTmpl;

use warnings;
use strict;

use base qw/Template::Benchmark::Engine/;

use Text::MiniTmpl 1.1.0 qw( render tmpl2code raw );

our $VERSION = '1.09_01';

our %feature_syntaxes = (
    literal_text              =>
        join( "\n", ( join( ' ', ( 'foo' ) x 12 ) ) x 5 ),
    scalar_variable           =>
        '#~ $_{scalar_variable} ~#',
    hash_variable_value       =>
        '#~ $_{hash_variable}->{hash_value_key} ~#',
    array_variable_value      =>
        '#~ $_{array_variable}->[ 2 ] ~#',
    deep_data_structure_value =>
        '#~ $_{this}->{is}{a}{very}{deep}{hash}{structure} ~#',
    array_loop_value          =>
        '&~foreach ( @{$_{array_loop}} ) {~&' .
        '#~ $_ ~#' .
        '&~}~&',
    hash_loop_value           =>
        '&~foreach ( sort( keys( %{$_{hash_loop}} ) ) ) {~&' .
        '#~ $_ ~#: #~ $_{hash_loop}->{$_} ~#' .
        '&~}~&',
    records_loop_value        =>
        '&~foreach ( @{$_{records_loop}} ) {~&' .
        '#~ $_->{ name } ~#: #~ $_->{ age } ~#' .
        '&~}~&',
    array_loop_template       =>
        '&~foreach ( @{$_{array_loop}} ) {~&' .
        '#~ $_ ~#' .
        '&~}~&',
    hash_loop_template        =>
        '&~foreach ( sort( keys( %{$_{hash_loop}} ) ) ) {~&' .
        '#~ $_ ~#: #~ $_{hash_loop}->{$_} ~#' .
        '&~}~&',
    records_loop_template     =>
        '&~foreach ( @{$_{records_loop}} ) {~&' .
        '#~ $_->{ name } ~#: #~ $_->{ age } ~#' .
        '&~}~&',
    constant_if_literal       =>
        '&~if( 1 ) {~&true&~}~&',
    variable_if_literal       =>
        '&~if( $_{variable_if} ) {~&true&~}~&',
    constant_if_else_literal  =>
        '&~if( 1 ) {~&true&~} else {~&' .
        'false&~}~&',
    variable_if_else_literal  =>
        '&~if( $_{variable_if_else} ) {~&true&~} ' .
        'else {~&false&~}~&',
    constant_if_template      =>
        '&~if( 1 ) {~&' .
        '#~ $_{template_if_true} ~#&~}~&',
    variable_if_template      =>
        '&~if( $_{variable_if} ) {~&' .
        '#~ $_{template_if_true} ~#&~}~&',
    constant_if_else_template =>
        '&~if( 1 ) {~&' .
        '#~ $_{template_if_true} ~#&~} ' .
        'else {~&' .
        '#~ $_{template_if_false} ~#&~}~&',
    variable_if_else_template =>
        '&~if( $_{variable_if_else} ) {~&' .
        '#~ $_{template_if_true} ~#&~} ' .
        'else {~&' .
        '#~ $_{template_if_false} ~#&~}~&',
    constant_expression       =>
        '#~ 10 + 12 ~#',
    variable_expression       =>
        '#~ $_{variable_expression_a} * $_{variable_expression_b} ~#',
    complex_variable_expression =>
        '#~ ( ( $_{variable_expression_a} * $_{variable_expression_b} ) + ' .
        '$_{variable_expression_a} - $_{variable_expression_b} ) / ' .
        '$_{variable_expression_b} ~#',
    constant_function         =>
        q[#~ substr( 'this has a substring.', 11, 9 ) ~#],
    variable_function         =>
        '#~ substr( $_{variable_function_arg}, 4, 2 ) ~#',
    );

sub syntax_type { return( 'embedded-perl' ); }
sub pure_perl { return( 1 ); }

sub benchmark_descriptions
{
    return( {
        TMT    =>
            "Text::MiniTmpl ($Text::MiniTmpl::VERSION)",
        TMTU   =>
            "Text::MiniTmpl ($Text::MiniTmpl::VERSION) with enabled Unicode",
        } );
}

sub benchmark_functions_for_uncached_string
{
    my ( $self ) = @_;

    return( undef );
}

sub benchmark_functions_for_uncached_disk
{
    my ( $self, $template_dir ) = @_;

    return( {
        TMT =>
            sub
            {
                raw(1);
                tmpl2code( $template_dir . '/' . $_[ 0 ] )->(
                    %{$_[ 1 ]}, %{$_[ 2 ]},
                )
            },
        TMTU =>
            sub
            {
                raw(0);
                tmpl2code( $template_dir . '/' . $_[ 0 ] )->(
                    %{$_[ 1 ]}, %{$_[ 2 ]},
                )
            },
        } );
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
    my ( $t, $out );

    return( {
        TMT =>
            sub
            {
                raw(1);
                \render( $template_dir . '/' . $_[ 0 ],
                    %{$_[ 1 ]}, %{$_[ 2 ]},
                )
            },
        TMTU =>
            sub
            {
                raw(0);
                # use ../../ to force different paths/caches for TMT and TMTU
                \render( ('../' x 20) . $template_dir . '/' . $_[ 0 ],
                    %{$_[ 1 ]}, %{$_[ 2 ]},
                )
            },
        } );
}

1;

__END__

=pod

=head1 NAME

Template::Benchmark::Engines::TextMiniTmpl - Template::Benchmark plugin for Text::MiniTmpl.

=head1 SYNOPSIS

Provides benchmark functions and template feature syntaxes to allow
L<Template::Benchmark> to benchmark the L<Text::MiniTmpl> template
engine.

=head1 AUTHOR

Sam Graham, C<< <libtemplate-benchmark-perl at illusori.co.uk> >>

Alex Efros, C<< <powerman-asdf@ya.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-benchmark at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Benchmark>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Benchmark::Engines::TextMiniTmpl


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


=head1 ACKNOWLEDGEMENTS

Thanks to Paul Seamons for creating the the bench_various_templaters.pl
script distributed with L<Template::Alloy>, which was the ultimate
inspiration for this module.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Sam Graham & Alex Efros.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
