package Template::Benchmark::Engines::TextScriptTemplate;
# ABSTRACT: Template::Benchmark plugin for Text::ScriptTemplate.

use warnings;
use strict;

use base qw/Template::Benchmark::Engine/;

use Text::ScriptTemplate;

use File::Spec;

our $VERSION = '1.09_02';

our %feature_syntaxes = (
    literal_text              =>
        join( "\n", ( join( ' ', ( 'foo' ) x 12 ) ) x 5 ),
    scalar_variable           =>
        '<%= $scalar_variable %>',
    hash_variable_value       =>
        '<%= $hash_variable->{hash_value_key} %>',
    array_variable_value      =>
        '<%= $array_variable->[ 2 ] %>',
    deep_data_structure_value =>
        '<%= $this->{is}->{a}->{very}->{deep}->{hash}->{structure} %>',
    array_loop_value          =>
        '<% foreach ( @{$array_loop} ) { %>' .
            '<%= $_ %>' .
        '<% } %>',
    hash_loop_value           =>
        '<% foreach ( sort( keys( %{$hash_loop} ) ) ) { %>' .
            '<%= $_ %>: <%= $hash_loop->{ $_ } %>' .
        '<% } %>',
    records_loop_value        =>
        '<% foreach ( @{$records_loop} ) { %>' .
            '<%= $_->{ name } %>: <%= $_->{ age } %>' .
        '<% } %>',
    array_loop_template       =>
        '<% foreach ( @{$array_loop} ) { %>' .
            '<%= $_ %>' .
        '<% } %>',
    hash_loop_template        =>
        '<% foreach ( sort( keys( %{$hash_loop} ) ) ) { %>' .
            '<%= $_ %>: <%= $hash_loop->{ $_ } %>' .
        '<% } %>',
    records_loop_template     =>
        '<% foreach ( @{$records_loop} ) { %>' .
            '<%= $_->{ name } %>: <%= $_->{ age } %>' .
        '<% } %>',
    constant_if_literal       =>
        '<% if( 1 ) { %>true<% } %>',
    variable_if_literal       =>
        '<% if( $variable_if ) { %>true<% } %>',
    constant_if_else_literal  =>
        '<% if( 1 ) { %>true<% } else { %>false<% } %>',
    variable_if_else_literal  =>
        '<% if( $variable_if_else ) { %>true<% } else { %>false<% } %>',
    constant_if_template      =>
        '<% if( 1 ) { %><%= $template_if_true %><% } %>',
    variable_if_template      =>
        '<% if( $variable_if ) { %><%= $template_if_true %>' .
        '<% } %>',
    constant_if_else_template =>
        '<% if( 1 ) { %><%= $template_if_true %><% } else { %>' .
        '<%= $template_if_false %><% } %>',
    variable_if_else_template =>
        '<% if( $variable_if_else ) { %>' .
        '<%= $template_if_true %><% } else { %>' .
        '<%= $template_if_false %><% } %>',
    constant_expression       =>
        '<%= 10 + 12 %>',
    variable_expression       =>
        '<%= $variable_expression_a * ' .
        '$variable_expression_b %>',
    complex_variable_expression =>
        '<%= ( ( $variable_expression_a * ' .
        '$variable_expression_b ) + ' .
        '$variable_expression_a - ' .
        '$variable_expression_b ) / ' .
        '$variable_expression_b %>',
    constant_function         =>
        q{<%= substr( 'this has a substring.', 11, 9 ) %>},
    variable_function         =>
        '<%= substr( $variable_function_arg, 4, 2 ) %>',
    );

sub syntax_type { return( 'embedded-perl' ); }
sub pure_perl { return( 1 ); }

sub benchmark_descriptions
{
    return( {
        TeScriTe =>
            "Text::ScriptTemplate ($Text::ScriptTemplate::VERSION)",
        } );
}

sub benchmark_functions_for_uncached_string
{
    my ( $self ) = @_;

    return( {
        TeScriTe =>
            sub
            {
                my $t = Text::ScriptTemplate->new();
                $t->pack( $_[ 0 ] );
                $t->setq(%{$_[ 1 ]});
                $t->setq(%{$_[ 2 ]});
                \$t->fill();
            },
        } );
}

sub benchmark_functions_for_uncached_disk
{
    my ( $self, $template_dir ) = @_;

    return( {
        TeScriTe =>
            sub
            {
                my $t = Text::ScriptTemplate->new();
                $t->load(File::Spec->catfile( $template_dir, $_[ 0 ] )),
                $t->setq(%{$_[ 1 ]});
                $t->setq(%{$_[ 2 ]});
                \$t->fill();
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
    my ( $t );

    return( {
        TeScriTe =>
            sub
            {
                if( $t )
                {
                    $t->{ hash } = {}; # Not brittle at all.
                }
                else
                {
                    $t = Text::ScriptTemplate->new();
                    $t->load(File::Spec->catfile( $template_dir, $_[ 0 ] )),
                }
                $t->setq(%{$_[ 1 ]});
                $t->setq(%{$_[ 2 ]});
                \$t->fill();
            },
        } );
}

1;

__END__

=pod

=head1 NAME

Template::Benchmark::Engines::TextScriptTemplate - Template::Benchmark plugin for Text::ScriptTemplate.

=head1 VERSION

version 1.09_02

=head1 SYNOPSIS

Provides benchmark functions and template feature syntaxes to allow
L<Template::Benchmark> to benchmark the L<Text::ScriptTemplate> template
engine.

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-benchmark at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Benchmark>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Benchmark::Engines::TextScriptTemplate

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
