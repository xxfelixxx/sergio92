#!/usr/local/bin/perl

#------ perl pragmas
use strict;
use warnings;

#------ perl Modules
use File::Glob;

#------ Constants
use constant DEBUG   => 0; # Set to 1 for lots of detail
use constant DIR_COV => 'covalently_bound';
use constant DIR_2_4 => '2_4';
use constant DIR_4_5 => '4_5';
use constant DIR_5_6 => '5_6';
use constant PERCENT => 70;

#----------------

debug("START\n");

# Create subdirectories
for my $dir ( DIR_COV, DIR_2_4, DIR_4_5, DIR_5_6 ) {
    next if -d $dir;
    print "Creating dir: $dir\n";
    mkdir $dir or die "Unable to create '$dir' : $!";
}

# Collect all of the Text file data into memory
my %text_data;
for my $txt_file ( glob '*txt' ) {
    $text_data{ $txt_file } = get_text_data($txt_file);
}
die "No text files found!" unless keys %text_data;

# For each PDB file, calculate distances between each ATOM and all HEMATM rows
my %atoms;
for my $pdb_file ( glob '*pdb' ) {
    $atoms{ $pdb_file } = process_pdb($pdb_file);
}
die "No PDB files found!" unless keys %atoms;

process_results( %atoms );

debug("FINISH\n");
exit 0;

#--- Subroutines (functions)

sub process_results {
    my (%atoms) = @_;

    # Go through the results and group them by Text File
    for my $pdb_file ( sort keys %atoms ) {
        my %distances_by_text_file;
        for my $atom ( @{ $atoms{ $pdb_file } } ) {
            my $atom_coord = $atom->{atom_coord};
            my $distances = $atom->{distances};
            debug("--> ATOM [ " . join(', ', @$atom_coord ) . " ]\n");
            for my $dist ( @$distances ) {
                # This is the text file
                my $txt_file = $dist->{text_file};
                my $dd = $dist->{distances};

                # This array will store all of the distances between the ATOM and the text file.
                my @ligand_distances;
                for my $ddd ( @{ $dd } ) {
                    push @ligand_distances, $ddd->{distance};
                    my $lig_coord = join(', ', @{$ddd->{ligand_coord}});
                    my $atom_lig_distance = sprintf("%0.1f", $ddd->{distance});
                    debug("----> LIGAND $txt_file : d = $atom_lig_distance [ $lig_coord ]\n");
                }
                push @{ $distances_by_text_file{ $txt_file } }, @ligand_distances;
            }
        }

        decide_which_text_files_should_move( %distances_by_text_file );
    }
}

sub decide_which_text_files_should_move {
    my ( %distances_by_text_file ) = @_;

    for my $txt_file ( sort keys %distances_by_text_file ) {
        my @distances = @{ $distances_by_text_file{ $txt_file } };  

        my @less_than_2 = find_between( 0, 2, \@distances );
        if ( scalar @less_than_2 ) {
            move_text( $txt_file,
                       scalar @less_than_2 == 1 ? DIR_COV : DIR_2_4 );
            next; # next text file
        }

        if ( percent_between( PERCENT, 2, 4, \@distances ) ) {
            move_text( $txt_file, DIR_2_4 );
            next;
        }

        if ( percent_between( PERCENT, 4, 5, \@distances ) ) {
            move_text( $txt_file, DIR_4_5 );
            next;
        }

        if ( percent_between( PERCENT, 5, 6, \@distances ) ) {
            move_text( $txt_file, DIR_5_6 );
            next;
        }

        # Fallback case
        print "Boo: no home for $txt_file....leaving it here\n";
    }
}

sub process_pdb {
    my ($pdb) = @_;
    debug("Working on $pdb...\n");
    open my $fh, "<$pdb" or die "Unable to open '$pdb' : $!";
    my @atoms;
    while(my $line = <$fh>) {
        chomp($line);
        if ( $line =~ /^ATOM / ) {
            my $atom_row = parse_row($line);
            my $distances = calculate_distances( $atom_row );
            push @atoms, { atom_coord => $atom_row, distances => $distances };
        }
    }
    return \@atoms;
}

sub calculate_distances {
    my ($atom_row) = @_;
    my @distances;
    for my $txt ( sort keys %text_data ) {
        my $ligands = $text_data{ $txt };
        my @lig_distances;
        for my $ligand ( @$ligands ) {
            my $lig_coord = $ligand->{ligand_coord};
            my $dist = distance( $atom_row, $lig_coord );
            push @lig_distances, { ligand_coord => $lig_coord, distance => $dist };
        }
        push @distances, { text_file => $txt, distances => \@lig_distances };
    }

    return \@distances;
}

sub get_text_data {
    my ($txt_file) = @_;
    open my $fh, "<", $txt_file or die "Unable to open '$txt_file' : $!";
    my @ligands;
    while( my $line = <$fh> ) {
        chomp($line);
        debug("$. : $line\n");
        if ( $line =~ m/^HETATM/ ) {
            my @lig_atoms = split '\t', $line;
            my $lig_coord = parse_row($line);
            push @ligands, { ligand_coord => $lig_coord };
        }
    }
    return \@ligands;
}

sub parse_row {
    # TODO: Use an existing library to parse these files
    my ($row) = @_;
    my (@row) = split /\s+/, $row; # Split on whitespace
    my ($x,$y,$z) = map { sprintf("%0.3f", $_) } @row[6..8];
    for ($x, $y, $z) {
        die "Invalid coordinate '$_' from line: \n'$row'\n"
            unless m|^-?\d+\.\d{3}$|; # 3 decimal places possibly negative
    }
    return [ $x, $y, $z ];
}

sub find_between {
    my ($min, $max, $array_ref) = @_;
    # [ 0, 1 ) i.e. closed min, open max interval
    my @results = grep { $min <= $_ && $_ < $max } @$array_ref;
    return @results;
}

sub percent_between {
    my ($percent, $min, $max, $array_ref) = @_;
    my $n = scalar @$array_ref;
    my @match = find_between( $min, $max, $array_ref );
    my $n_match = scalar @match;
    return ( ( $n_match / $n ) > ( $percent / 100 ) ) ? 1 : 0;
}

sub move_text {
    my ($txt_file, $dest_dir) = @_;
    print "Moving $txt_file to $dest_dir\n";
    rename $txt_file, "$dest_dir/$txt_file"
        or die "Unable to move $txt_file to $dest_dir : $!";
}

sub distance {
    my ($v1, $v2) = @_;
    my $len1 = scalar @$v1;
    my $len2 = scalar @$v2;
    $len1 == $len2
        or die "Invalid vectors [ " . @$v1 . " ] and [ " . @$v2 . " ]";
    my $squared_differences = 0;
    for my $ii ( 0 .. $len1-1 ) {
        $squared_differences += ( $v1->[ $ii ] - $v2->[ $ii ] ) ** 2;
    }
    return sqrt($squared_differences);
}

sub debug {
    print join(' ', 'DEBUG: ', @_) if DEBUG;
}
