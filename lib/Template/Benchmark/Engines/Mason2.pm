package Template::Benchmark::Engines::Mason2;

use warnings;
use strict;

use base qw/Template::Benchmark::Engine/;

use Mason;

use File::Spec;

our $VERSION = '1.09_02';

our %feature_syntaxes = (
    literal_text              =>
        join( "\n", ( join( ' ', ( 'foo' ) x 12 ) ) x 5 ),
    scalar_variable           =>
        '<% $.args->{scalar_variable} %>',
    hash_variable_value       =>
        '<% $.args->{hash_variable}->{hash_value_key} %>',
    array_variable_value      =>
        '<% $.args->{array_variable}->[ 2 ] %>',
    deep_data_structure_value =>
        '<% $.args->{this}->{is}{a}{very}{deep}{hash}{structure} %>',
    array_loop_value          =>
        '<%perl>foreach ( @{$.args->{array_loop}} ) {</%perl>' .
        '<% $_ %>' .
        '<%perl>}</%perl>' . "\n",
    hash_loop_value           =>
        '<%perl>foreach ( sort( keys( %{$.args->{hash_loop}} ) ) ) {</%perl>' .
        '<% $_ %>: <% $.args->{hash_loop}->{$_} %>' .
        '<%perl>}</%perl>' . "\n",
    records_loop_value        =>
        '<%perl>foreach ( @{$.args->{records_loop}} ) {</%perl>' .
        '<% $_->{ name } %>: <% $_->{ age } %>' .
        '<%perl>}</%perl>' . "\n",
    array_loop_template       =>
        '<%perl>foreach ( @{$.args->{array_loop}} ) {</%perl>' .
        '<% $_ %>' .
        '<%perl>}</%perl>' . "\n",
    hash_loop_template        =>
        '<%perl>foreach ( sort( keys( %{$.args->{hash_loop}} ) ) ) {</%perl>' .
        '<% $_ %>: <% $.args->{hash_loop}->{$_} %>' .
        '<%perl>}</%perl>' . "\n",
    records_loop_template     =>
        '<%perl>foreach ( @{$.args->{records_loop}} ) {</%perl>' .
        '<% $_->{ name } %>: <% $_->{ age } %>' .
        '<%perl>}</%perl>' . "\n",
    constant_if_literal       =>
        '<%perl>if( 1 ) {</%perl>true<%perl>}</%perl>' . "\n",
    variable_if_literal       =>
        '<%perl>if( $.args->{variable_if} ) {</%perl>true<%perl>}</%perl>' . "\n",
    constant_if_else_literal  =>
        '<%perl>if( 1 ) {</%perl>true<%perl>} else {</%perl>' .
        'false<%perl>}</%perl>' . "\n",
    variable_if_else_literal  =>
        '<%perl>if( $.args->{variable_if_else} ) {</%perl>true<%perl>} ' .
        'else {</%perl>false<%perl>}</%perl>' . "\n",
    constant_if_template      =>
        '<%perl>if( 1 ) {</%perl>' .
        '<% $.args->{template_if_true} %><%perl>}</%perl>' . "\n",
    variable_if_template      =>
        '<%perl>if( $.args->{variable_if} ) {</%perl>' .
        '<% $.args->{template_if_true} %><%perl>}</%perl>' . "\n",
    constant_if_else_template =>
        '<%perl>if( 1 ) {</%perl>' .
        '<% $.args->{template_if_true} %><%perl>} ' .
        'else {</%perl>' .
        '<% $.args->{template_if_false} %><%perl>}</%perl>' . "\n",
    variable_if_else_template =>
        '<%perl>if( $.args->{variable_if_else} ) {</%perl>' .
        '<% $.args->{template_if_true} %><%perl>} ' .
        'else {</%perl>' .
        '<% $.args->{template_if_false} %><%perl>}</%perl>' . "\n",
    constant_expression       =>
        '<% 10 + 12 %>',
    variable_expression       =>
        '<% $.args->{variable_expression_a} * $.args->{variable_expression_b} %>',
    complex_variable_expression =>
        '<% ( ( $.args->{variable_expression_a} * $.args->{variable_expression_b} ) + ' .
        '$.args->{variable_expression_a} - $.args->{variable_expression_b} ) / ' .
        '$.args->{variable_expression_b} %>',
    constant_function         =>
        q[<% substr( 'this has a substring.', 11, 9 ) %>],
    variable_function         =>
        '<% substr( $.args->{variable_function_arg}, 4, 2 ) %>',
    );

sub syntax_type { return( 'embedded-perl' ); }
sub pure_perl { return( 1 ); }

sub benchmark_descriptions
{
    return( {
        M2  =>
            "Mason ($Mason::VERSION)",
        } );
}

#  These flags lifted from HTML::Mason::Admin PERFORMANCE section.
#    code_cache_max_size => 0,  # turn off memory caching
#    use_object_files => 0,     # turn off disk caching
#    static_source => 1,        # turn off disk stat()s
#    enable_autoflush = 0,      # turn off dynamic autoflush checking

sub benchmark_functions_for_uncached_disk
{
    my ( $self, $template_dir ) = @_;

    return( {
        M2 =>
            sub
            {
                my $out = '';
                my $t = Mason->new(
                    comp_root               => $template_dir,
                    static_source           => 1,
                    out_method              => \$out,
                    autoextend_request_path => 0,
                    top_level_extensions    => [],
                    );

                $t->run(
                    #  Don't use File::Spec, Mason reads it like a URL path.
                    '/' . $_[ 0 ],
                    %{$_[ 1 ]}, %{$_[ 2 ]},
                    );
                \$out;
            },
        } );
}

sub benchmark_functions_for_disk_cache
{
    my ( $self, $template_dir, $cache_dir ) = @_;

    return( {
        M2 =>
            sub
            {
                my $out = '';
                my $t = Mason->new(
                    comp_root               => $template_dir,
                    data_dir                => $cache_dir,
                    static_source           => 1,
                    out_method              => \$out,
                    autoextend_request_path => 0,
                    top_level_extensions    => [],
                    );

                $t->run(
                    #  Don't use File::Spec, Mason reads it like a URL path.
                    '/' . $_[ 0 ],
                    %{$_[ 1 ]}, %{$_[ 2 ]},
                    );
                \$out;
            },
        } );
}

sub benchmark_functions_for_instance_reuse
{
    my ( $self, $template_dir, $cache_dir ) = @_;
    my ( $t, $out );

    $t = Mason->new(
        comp_root               => $template_dir,
        data_dir                => $cache_dir,
        static_source           => 1,
        out_method              => \$out,
        autoextend_request_path => 0,
        top_level_extensions    => [],
        );

    return( {
        M2 =>
            sub
            {
                $out = '';
                $t->run(
                    #  Don't use File::Spec, Mason reads it like a URL path.
                    '/' . $_[ 0 ],
                    %{$_[ 1 ]}, %{$_[ 2 ]},
                    );
                \$out;
            },
        } );
}

1;
