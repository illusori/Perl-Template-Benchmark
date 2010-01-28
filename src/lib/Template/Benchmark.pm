package Template::Benchmark;

use warnings;
use strict;

use Benchmark;

use POSIX qw(tmpnam);
use File::Path qw(mkpath rmtree);
use File::Spec;
use IO::File;

use Module::Pluggable search_path => 'Template::Benchmark::Engines',
                      sub_name    => 'engine_plugins';

our $VERSION = '0.99_01';

my @valid_features = qw/
    literal_padding
    scalar_variable
    hash_variable_value
    array_variable_value
    deep_data_structure_value
    array_loop
    hash_loop
    records_loop
    constant_if
    variable_if
    constant_if_else
    variable_if_else
    constant_expression
    variable_expression
    complex_variable_expression
    constant_function
    variable_function
    /;

my @valid_benchmark_types = qw/
    uncached_string
    disk_cache
    shared_memory_cache
    memory_cache
    /;

my %option_defaults = (
    #  Feature options: these should only default on if they're
    #  widely supported, so that the default benchmark covers
    #  most template engines.
    literal_padding             => 1,
    scalar_variable             => 1,
    hash_variable_value         => 0,
    array_variable_value        => 0,
    deep_data_structure_value   => 0,
    array_loop                  => 0,
#  TODO: bugger, hash loop isn't going to have a cross-engine ordering.
    hash_loop                   => 0,
    records_loop                => 1,
    constant_if                 => 0,
    variable_if                 => 1,
    constant_if_else            => 0,
    variable_if_else            => 1,
    constant_expression         => 0,
    variable_expression         => 0,
    complex_variable_expression => 0,
    constant_function           => 0,
    variable_function           => 0,

    #  Benchmark types.
    uncached_string             => 1,
    disk_cache                  => 1,
    shared_memory_cache         => 1,
    memory_cache                => 1,

    #  Other options.
    template_repeats => 30,
    duration         => 10,
    style            => 'none',
    keep_tmp_dirs    => 0,
    );

#  Which engines to try first as the 'reference output' for templates.
#  Note that this is merely a matter of author convenience: all template
#  engine outputs must match, this merely determines which should be
#  cited as 'correct' in the case of a mismatch.  This should generally
#  be a template engine that provides most features, otherwise it won't
#  be an _available_ template engine when we need it.
#  For author convenience I'm using Template::Sandbox as the prefered
#  reference, however Template::Toolkit will make a better reference
#  choice once this module has stabilized.
my $reference_preference = 'TS';

my $var_hash1 = {
    scalar_variable => 'I is a scalar, yarr!',
    hash_variable   => {
        'hash_value_key' =>
            'I spy with my little eye, something beginning with H.',
        },
    array_variable   => [ qw/I have an imagination honest/ ],
    this => { is => { a => { very => { deep => { hash => {
        structure => "My god, it's full of hashes.",
        } } } } } },
    };
my $var_hash2 = {
    array_loop => [ qw/five four three two one coming ready or not/ ],
    hash_loop  => {
        aaa => 'first',
        bbb => 'second',
        ccc => 'third',
        ddd => 'fourth',
        eee => 'fifth',
        },
    records_loop => [
        { name => 'Joe Bloggs',      age => 16, },
        { name => 'Fred Bloggs',     age => 23, },
        { name => 'Nigel Bloggs',    age => 43, },
        { name => 'Tarquin Bloggs',  age => 143, },
        { name => 'Geoffrey Bloggs', age => 13, },
        ],
    variable_if      => 1,
    variable_if_else => 0,
    variable_expression_a => 20,
    variable_expression_b => 10,
    variable_function_arg => 'Hi there',
    };

sub new
{
    my $this = shift;
    my ( $self, $class );

    $self = {};
    $class = ref( $this ) || $this;
    bless $self, $class;

    $self->{ options } = {};
    while( my $opt = shift )
    {
        $self->{ options }->{ $opt } = shift;
    }
    foreach my $opt ( keys( %option_defaults ) )
    {
        $self->{ options }->{ $opt } //= $option_defaults{ $opt };
    }

    $self->{ engines } = [];
    $self->{ engine_errors } = {};
    foreach my $plugin ( $self->engine_plugins() )
    {
        eval "use $plugin";
        if( $@ )
        {
            my $leaf = _engine_leaf( $plugin );
            $self->{ engine_errors }->{ $leaf } //= [];
            push @{$self->{ engine_errors }->{ $leaf }},
                "Engine module load failure: $@";
        }
        else
        {
            push @{$self->{ engines }}, $plugin;
        }
    }

    $self->{ template_dir } = tmpnam();
    $self->{ cache_dir }    = $self->{ template_dir } . '.cache';
    #  TODO: failure check.
    mkpath( $self->{ template_dir } );
    mkpath( $self->{ cache_dir } );

    $self->{ benchmark_types } =
        [ grep { $self->{ options }->{ $_ } } @valid_benchmark_types ];
    #  TODO: sanity-check some are left.

    $self->{ features } =
        [ grep { $self->{ options }->{ $_ } } @valid_features ];
    #  TODO: sanity-check some are left.

    $self->{ templates }           = {};
    $self->{ benchmark_functions } = {};
    $self->{ descriptions }        = {};
    ENGINE: foreach my $engine ( @{$self->{ engines }} )
    {
        my ( %benchmark_functions, $template_dir, $cache_dir, $template,
            $template_filename, $fh, $descriptions, $missing_syntaxes, $leaf );

        $leaf = _engine_leaf( $engine );
        $self->{ engine_errors }->{ $leaf } //= [];

        $template_dir =
            File::Spec->catfile( $self->{ template_dir }, $leaf );
        $cache_dir    =
            File::Spec->catfile( $self->{ cache_dir },    $leaf );
        #  TODO: failure check
        mkpath( $template_dir );
        mkpath( $cache_dir );

        foreach my $benchmark_type ( @{$self->{ benchmark_types }} )
        {
            my ( $method, $functions );

            no strict 'refs';

            $method = "benchmark_functions_for_${benchmark_type}";

            next unless $engine->can( $method );

            $functions = $engine->$method( $template_dir, $cache_dir );

            next unless $functions and scalar( keys( %{$functions} ) );

            $benchmark_functions{ $benchmark_type } = $functions;
        }

        unless( %benchmark_functions )
        {
            push @{$self->{ engine_errors }->{ $leaf }},
                'No matching benchmark functions.';
            next ENGINE;
        }

        $template = '';
        $missing_syntaxes = '';
        foreach my $feature ( @{$self->{ features }} )
        {
            my ( $feature_syntax );

            $feature_syntax = $engine->feature_syntax( $feature );
            if( defined( $feature_syntax ) )
            {
                $template .= $feature_syntax . "\n";
            }
            else
            {
                $missing_syntaxes .= ' ' . $feature;
            }
        }

        if( $missing_syntaxes )
        {
            push @{$self->{ engine_errors }->{ $leaf }},
                "No syntaxes provided for:$missing_syntaxes.";
            next ENGINE;
        }

        $template = $template x $self->{ options }->{ template_repeats };

        $template_filename =
            File::Spec->catfile( $template_dir, $leaf . '.txt' );
        $fh = IO::File->new( "> $template_filename" ) or
            die "Unable to write $template_filename: $!";
        $fh->print( $template );
        $fh->close();

        $template_filename = $leaf . '.txt';

        $descriptions = $engine->benchmark_descriptions();

        foreach my $type ( keys( %benchmark_functions ) )
        {
            $self->{ benchmark_functions }->{ $type } ||= {};

            foreach my $tag ( keys( %{$benchmark_functions{ $type }} ) )
            {
                my ( $function );

                $function = $benchmark_functions{ $type }->{ $tag };
                if( $type =~ /_string$/ )
                {
                    $self->{ benchmark_functions }->{ $type }->{ $tag } =
                        sub
                        {
                            $function->( $template,
                                $var_hash1, $var_hash2 );
                        };
                }
                else
                {
                    $self->{ benchmark_functions }->{ $type }->{ $tag } =
                        sub
                        {
                            $function->( $template_filename,
                                $var_hash1, $var_hash2 );
                        };
                }
                $self->{ descriptions }->{ $tag } = $descriptions->{ $tag };
            }
        }

        delete $self->{ engine_errors }->{ $leaf }
            unless @{$self->{ engine_errors }->{ $leaf }};
    }

    return( $self );
}

sub benchmark
{
    my ( $self ) = @_;
    my ( $duration, $style, $result, $reference, @outputs );

    $duration = $self->{ options }->{ duration };
    $style    = $self->{ options }->{ style };

    #  First up, check each benchmark function produces the same
    #  output as all the others.  This also serves to ensure that
    #  the caches become populated for those benchmarks that are
    #  cached.
    @outputs = ();
    $reference = 0;
    foreach my $type ( @{$self->{ benchmark_types }} )
    {
        foreach my $tag
            ( keys( %{$self->{ benchmark_functions }->{ $type }} ) )
        {
            push @outputs, [
                $type,
                $tag,
                $self->{ benchmark_functions }->{ $type }->{ $tag }->(),
                ];
            $reference = $#outputs if $tag eq $reference_preference;
        }
    }

    return( {
        result => 'NO BENCHMARKS TO RUN',
        } )
        unless @outputs;

#use Data::Dumper;
#print "Outputs: ", Data::Dumper::Dumper( \@outputs ), "\n";

    $result = {
        result    => 'MISMATCHED TEMPLATE OUTPUT',
        reference =>
            {
                type   => $outputs[ $reference ]->[ 0 ],
                tag    => $outputs[ $reference ]->[ 1 ],
                output => $outputs[ $reference ]->[ 2 ],
            },
        failures => [],
        };
    foreach my $output ( @outputs )
    {
        push @{$result->{ failures }},
            {
                type   => $output->[ 0 ],
                tag    => $output->[ 1 ],
                output => $output->[ 2 ] // "[no content returned]\n",
            }
            if !defined( $output->[ 2 ] ) or
               $output->[ 2 ] ne $result->{ reference }->{ output };
    }

    return( $result ) unless $#{$result->{ failures }} == -1;

    #  OK, all template output matched, time to do the benchmarks.

    $result = {
        result    => 'SUCCESS',
        };

    $result->{ start_time } = time();
    $result->{ title } = 'Template Benchmark @' .
        localtime( $result->{ start_time } );
    $result->{ descriptions } = { %{$self->{ descriptions }} };

    $result->{ benchmarks } = [];
    if( $duration )
    {
        foreach my $type ( @{$self->{ benchmark_types }} )
        {
            my ( $timings, $comparison );

            $timings = Benchmark::timethese( -$duration,
                $self->{ benchmark_functions }->{ $type }, $style );
            $comparison = Benchmark::cmpthese( $timings, $style );

            push @{$result->{ benchmarks }},
                {
                    type       => $type,
                    timings    => $timings,
                    comparison => $comparison,
                };
        }
    }

    return( $result );
}

sub DESTROY
{
    my ( $self ) = @_;

    #  Use a DESTROY to clean up, so that we occur in case of errors.
    if( $self->{ options }->{ keep_tmp_dirs } )
    {
        print "Not removing cache dir ", $self->{ cache_dir }, "\n"
            if $self->{ cache_dir };
        print "Not removing template dir ", $self->{ template_dir }, "\n"
            if $self->{ template_dir };
    }
    else
    {
        rmtree( $self->{ cache_dir } )    if $self->{ cache_dir };
        rmtree( $self->{ template_dir } ) if $self->{ template_dir };
    }
}

sub default_options { return( %option_defaults ); }
sub valid_benchmark_types { return( @valid_benchmark_types ); }
sub valid_features { return( @valid_features ); }

sub engine_errors
{
    my ( $self ) = @_;
    return( $self->{ engine_errors } );
}

sub number_of_benchmarks
{
    my ( $self ) = @_;
    my ( $num_benchmarks );

    $num_benchmarks = 0;
    foreach my $type ( @{$self->{ benchmark_types }} )
    {
        $num_benchmarks +=
            scalar( keys( %{$self->{ benchmark_functions }->{ $type }} ) );
    }

    return( $num_benchmarks );
}

sub estimate_benchmark_duration
{
    my ( $self ) = @_;
    my ( $duration );

    $duration = $self->{ options }->{ duration };

    return( $duration * $self->number_of_benchmarks() );
}

sub _engine_leaf
{
    my ( $engine ) = @_;

    $engine =~ /\:\:([^\:]*)$/;
    return( $1 );
}

1;

__END__

=pod

=head1 NAME

Template::Benchmark - Pluggable benchmarker to cross-compare template systems.

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code feature.

    use Template::Benchmark;

    my $foo = Template::Benchmark->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 function1

=head2 function2

=head1 AUTHOR

Sam Graham, C<< <libtemplate-benchmark-perl at illusori.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-benchmark at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Benchmark>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Benchmark


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
