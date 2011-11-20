package Template::Benchmark::Engines::TemplateSimple;

use warnings;
use strict;

use base qw/Template::Benchmark::Engine/;

use Template::Simple;

our $VERSION = '1.09_02';

our %feature_syntaxes = (
    literal_text              =>
        join( "\n", ( join( ' ', ( 'foo' ) x 12 ) ) x 5 ),
    scalar_variable           =>
        '[% scalar_variable %]',
    hash_variable_value       =>
        '[% start hash_variable %][% hash_value_key %][% end hash_variable %]',
    array_variable_value      =>
        undef,
    deep_data_structure_value =>
        #  Erkle.
        '[% start this %][% start is %][% start a %][% start very %]' .
        '[% start deep %][% start hash %]' .
        '[% structure %]' .
        '[% end hash %][% end deep %]' .
        '[% end very %][% end a %][% end is %][% end this %]',
    array_loop_value          =>
        undef,
#        '[% start array_loop %][% end array_loop %]',
    hash_loop_value           =>
        undef,
    records_loop_value        =>
        '[% start records_loop %][% name %]: ' .
        '[% age %][% end records_loop %]',
    array_loop_template       =>
        undef,
    hash_loop_template        =>
        undef,
    records_loop_template     =>
        '[% start records_loop %][% name %]: ' .
        '[% age %][% end records_loop %]',
    constant_if_literal       =>
        undef,
    variable_if_literal       =>
        undef,
    constant_if_else_literal  =>
        undef,
    variable_if_else_literal  =>
        undef,
    constant_if_template      =>
        undef,
    variable_if_template      =>
        undef,
    constant_if_else_template =>
        undef,
    variable_if_else_template =>
        undef,
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

sub mandatory_template_file_suffix { return( '.tmpl' ); }

sub benchmark_descriptions
{
    return( {
        TSi  =>
            "Template::Simple ($Template::Simple::VERSION)",
        TSi_C  =>
            "Template::Simple ($Template::Simple::VERSION) with pre-compilation",
        } );
}

sub benchmark_functions_for_uncached_string
{
    my ( $self ) = @_;

    return( {
        TSi =>
            sub
            {
                my $t = Template::Simple->new();
                $t->render( $_[ 0 ], { %{$_[ 1 ]}, %{$_[ 2 ]} } );
            },
        } );
}

sub benchmark_functions_for_uncached_disk
{
    my ( $self, $template_dir ) = @_;
    my ( @template_dirs );

    @template_dirs = ( $template_dir );

    return( {
        TSi =>
            sub
            {
                my $t = Template::Simple->new(
                    search_dirs => \@template_dirs,
                    );
                $t->render( $_[ 0 ], { %{$_[ 1 ]}, %{$_[ 2 ]} } );
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
    my ( $t, $tc, @template_dirs );

    @template_dirs = ( $template_dir );

    return( {
        TSi =>
            sub
            {
                $t = Template::Simple->new(
                    search_dirs => \@template_dirs,
                    ) unless $t;
                $t->render( $_[ 0 ], { %{$_[ 1 ]}, %{$_[ 2 ]} } );
            },
        TSi_C =>
            sub
            {
                unless( $tc )
                {
                    $tc = Template::Simple->new(
                        search_dirs => \@template_dirs,
                        );
                    $tc->compile( $_[ 0 ] );
                }
                $tc->render( $_[ 0 ], { %{$_[ 1 ]}, %{$_[ 2 ]} } );
            },
        } );
}

1;

__END__

=pod

=head1 NAME

Template::Benchmark::Engines::TemplateSimple - Template::Benchmark plugin for Template::Simple.

=head1 SYNOPSIS

Provides benchmark functions and template feature syntaxes to allow
L<Template::Benchmark> to benchmark the L<Template::Simple> template
engine.

=head1 AUTHOR

Sam Graham, C<< <libtemplate-benchmark-perl at illusori.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-benchmark at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Benchmark>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Benchmark::Engines::TemplateSimple


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

Copyright 2010 Sam Graham.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
