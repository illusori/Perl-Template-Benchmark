package Template::Benchmark::Engines::TextFastTemplate;
# ABSTRACT: Template::Benchmark plugin for Text::FastTemplate.

use warnings;
use strict;

use base qw/Template::Benchmark::Engine/;

use Text::FastTemplate;

our $VERSION = '1.09_02';

our %feature_syntaxes = (
    literal_text              =>
        join( "\n", ( join( ' ', ( 'foo' ) x 12 ) ) x 5 ),
    scalar_variable           =>
        '##scalar_variable##',
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
        # Unfortunately inserts linebreaks... nuke them in postprocess
        "#for ##records_loop##\n" .
        "##name##: ##age##__NUKE__\n" .
        "#endfor\n",
    array_loop_template       =>
        undef,
    hash_loop_template        =>
        undef,
    records_loop_template     =>
        # Unfortunately inserts linebreaks... nuke them in postprocess
        "#for ##records_loop##\n" .
        "##name##: ##age##__NUKE__\n" .
        "#endfor\n",
    constant_if_literal       =>
        "#if 1\ntrue\n#endif",
    variable_if_literal       =>
        "#if ##variable_if##\ntrue\n#endif",
    constant_if_else_literal  =>
        "#if 1\ntrue\n#else\nfalse\n#endif",
    variable_if_else_literal  =>
        "#if ##variable_if_else##\ntrue\n#else\nfalse\n#endif",
    constant_if_template      =>
        "#if 1\n##template_if_true##\n#endif",
    variable_if_template      =>
        "#if ##variable_if##\n##template_if_true##\n#endif",
    constant_if_else_template =>
        "#if 1\n##template_if_true##\n#else\n##template_if_false##\n#endif",
    variable_if_else_template =>
        "#if ##variable_if_else##\n##template_if_true##\n#else\n##template_if_false##\n#endif",
    constant_expression       =>
        undef,
    variable_expression       =>
        undef,
    complex_variable_expression =>
        undef,
    constant_function         =>
        undef,
    variable_function         =>
        undef,
    );

sub syntax_type { return( 'mini-language' ); }
sub pure_perl { return( 1 ); }

sub benchmark_descriptions
{
    return( {
        TeFastTe =>
            "Text::FastTemplate ($Text::FastTemplate::VERSION)",
        } );
}

# There's unavoidable whitespace in the loops, nuke it.
sub postprocess_output
{
    my ( $self, $output ) = @_;

    $output =~ s/__NUKE__\s//g;
    return( $output );
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
        TeFastTe =>
            sub
            {
                my $t = Text::FastTemplate->new(
                    path => $template_dir,
                    file => $_[ 0 ],
                    );
                \$t->output( { %{$_[ 1 ]}, %{$_[ 2 ]} } );
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

    return( {
        TeFastTe =>
            sub
            {
                my $t = Text::FastTemplate->new(
                    key  => 'TemplateBenchmark',
                    path => $template_dir,
                    file => $_[ 0 ],
                    );
                \$t->output( { %{$_[ 1 ]}, %{$_[ 2 ]} } );
            },
        } );
}

sub benchmark_functions_for_instance_reuse
{
    my ( $self, $template_dir, $cache_dir ) = @_;
    my ( $t );

    return( {
        TeFastTe =>
            sub
            {
                $t = Text::FastTemplate->new(
                    key  => 'TemplateBenchmark',
                    path => $template_dir,
                    file => $_[ 0 ],
                    ) unless $t;
                \$t->output( { %{$_[ 1 ]}, %{$_[ 2 ]} } );
            },
        } );
}

1;

__END__

=pod

=head1 NAME

Template::Benchmark::Engines::TextFastTemplate - Template::Benchmark plugin for Text::FastTemplate.

=head1 VERSION

version 1.09_02

=head1 SYNOPSIS

Provides benchmark functions and template feature syntaxes to allow
L<Template::Benchmark> to benchmark the L<Text::FastTemplate> template
engine.

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-benchmark at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Benchmark>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Benchmark::Engines::TextFastTemplate

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
