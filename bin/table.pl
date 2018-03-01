#!/usr/bin/env perl

use strict;
use warnings;
# use diagnostics; # useful but noisy

use Text::SimpleTable::AutoWidth;

my $file = $ARGV[0] || die "usage: $0 file\n";
-f $file or die "Pass in a file!";

my $table = Text::SimpleTable::AutoWidth->new();
$table->captions(['PDB','SOURCE','EXPDTA','REMARK','HETNAM','FORMUL']);

# Now it reads more logically
for my $block ( read_file_into_blocks( $file ) ) {
    my $header = get_header( $block );
    my $source = get_source( $block );
    my $expdta = get_expdta( $block );
    my $remark = get_remark( $block );
    my $formul = get_formul( $block );

    $table->row($header,
                remove_trailing_punctuation($source),
                $expdta,
                remove_trailing_punctuation($remark),
                join("\n", map { $formul->{$_}->{HETNAM} } sort keys %$formul ),
                join("\n", map { $formul->{$_}->{FORMUL} } sort keys %$formul ),
    );
}
print $table->draw();
exit 0;

sub read_file_into_blocks {
    my ($file) = @_;

    open( my $fh, "$file" ) or die "Unable to open $file : $!";
    chomp( my @file_lines = <$fh> );
    close $fh;

    my @blocks;
    my $last_block = {};
    for my $line (@file_lines) {
        my @fields = split /\s+/, $line;
        if ( 'END' eq $fields[0] ) {
            push @blocks, $last_block;
            $last_block = {};
        } else {
            my $type = shift @fields;
            push @{ $last_block->{ $type } }, [ @fields ];
        }
    }
    return @blocks;
}

sub get_all {
    my ($block, $section) = @_;
    return join(' ', @{ $block->{$section}->[0] } );
}

sub get_last {
    my ($block, $section) = @_;
    return $block->{$section}->[0]->[-1]; # last item from first sub array
}

sub get_last_two {
    my ($block, $section) = @_;
    my $str = join(' ',
                $block->{$section}->[0]->[-2],
                $block->{$section}->[0]->[-1] );

    return $str;
}

sub remove_trailing_punctuation {
    my ($txt) = @_;
    $txt =~ s/[\.\;]$//; # Remove trailing semicolons or periods
    return $txt;
}

sub get_all_lines {
    my ($block, $section) = @_;
    my @lines;
    for my $ii ( 0 .. $#{ $block->{$section} } ) {
        push @lines, join(' ', @{ $block->{$section}->[$ii] });
    }
    return @lines;
}

sub get_hetnam_data {
    my ($block) = @_;

    my %hetnam;
    for my $ii ( 0 .. $#{ $block->{HETNAM} } ) {
        my @data = @{ $block->{HETNAM}->[$ii] };
        my $atom = shift @data;
        $hetnam{$atom} = join(' ', @data);
    }
    return \%hetnam;
}

sub get_formul {
    my ($block) = @_;
    my ($hetnam) = get_hetnam_data($block);
    my $formul;
  FORMUL:
    for my $ii ( 0 .. $#{ $block->{FORMUL} } ) {
        my @data = @{ $block->{FORMUL}->[$ii] };
        for my $ion (@data) {
            if ( exists $hetnam->{$ion} ) {
                $formul->{$ion}->{FORMUL} = join(' ', @data);
                $formul->{$ion}->{HETNAM} = $hetnam->{$ion};
                next FORMUL;
            }
        }
        # Didn't match any HETNAM
    }
    return $formul;
}

sub get_header {
    my ($block) = @_;
    return get_last( $block, 'HEADER');
}

sub get_source {
    my ($block) = @_;
    return get_last_two( $block, 'SOURCE');
}

sub get_expdta {
    my ($block) = @_;
    return get_all( $block, 'EXPDTA');
}

sub get_remark {
    my ($block) = @_;
    return get_last_two( $block, 'REMARK');
}
