#!/usr/bin/env perl

use warnings;
use strict;
 
# Attempt to match the pdbs in pdb_list to one of the species in table_list
# Replace the matching pdb with the full pdb_name from pdb_list
# Print out only the matching species
#
# A table_list file looks like:
# ----------------------------
# 3BP2_HUMAN	Homo sapiens	P78314	PDB; 2CR4; NMR; -; A=446-558.
# 					PDB; 3TWR; X-ray; 1.55 A; E/F/G/H=410-425.
#					
# 3L21A_BUNMU	Bungarus multicinctus	P60615	PDB; 1ABT; NMR; -; A=22-95.
# 					PDB; 1BXP; NMR; -; A=22-95.
# 					PDB; 1HAA; NMR; -; A=22-95.
#
# A pdb_list file looks like:
# --------------------------
#
# 5E65_5N6.pdb
# 5E68_MET_PAV.pdb
# 5E6E_MBN.pdb

# -- Input Validation
scalar @ARGV == 2
    or die "usage: $0 table_list pdb_list\n";

my ($table_list, $pdb_list) = @ARGV;
die "Invalid table list" unless -f $table_list;
die "Invalid pdb list" unless -f $pdb_list;

# -- Read Input
my $table = parse_table_list($table_list);
my $pdbs  = parse_pdb_list($pdb_list);

# -- Do the work
$table = match_up( $table, $pdbs );

# -- Print them out
my $last_order = -1;
my $species_matched = 0;
for my $pdb ( get_matching_pdbs_in_order( $table ) ) {
    my $order = $table->{$pdb}->{order};
    if ( $last_order != $order ) {
        # Only print them only once, ignore duplicates, i.e. $last_order == $order
        print $table->{$pdb}->{txt} . "\n\n";
        $last_order = $order;
        $species_matched++;
    }
}
warn "There are $species_matched species matches\n";


exit 0; # Success

sub get_matching_pdbs_in_order {
    my ($table) = @_;
    # Read backwords: Find the keys which are matched,
    #                 and return them in 'order' order numerically ascending
    my @matches = sort { $table->{$a}->{order} <=> $table->{$b}->{order} }
                  grep { $table->{$_}->{matched} == 1 }
                  keys %$table;
    return @matches;
}

sub match_up {
    my ($table, $pdbs) = @_;
    for my $pdb ( sort keys %$pdbs ) {
        if ( exists $table->{ $pdb } ) {
            # Match
            my $txt = $table->{$pdb}->{txt};
            my $replace = $pdbs->{$pdb};
            $txt =~ s|$pdb|$replace|sg;
            $table->{ $pdb }->{txt} = $txt;
            $table->{ $pdb }->{matched} = 1;
        }
    }
    return $table;
}

sub parse_table_list {
    my ($table_list) = @_;
    open my $fh, "<", $table_list or die "Unable to open '$table_list' : $!";
    my @blocks;
    my $txt = '';
    while ( my $line = <$fh> ) {
        if ($line =~ m/\w/) {
            $txt .= $line;
        } else {
            chomp($txt);
            push @blocks, $txt;
            $txt = '';
        }
    }

    my $table;
    my $block_count = 0;
    for my $block ( @blocks ) {
        # i dont know how people get with metacharacters..
        # You only need to remember a few...
        # ^ = match beginning of string
        # . = match any character
        # + = 1-or-more times
        # ? = but don't be greedy
        # \s+ = spaces
        # PDB = the string PDB
        # |s means treat the string as one long line
        # thanks!
        my ($header) = $block =~ m|^(.+?)\s+PDB|s; 
        my @head = split /\s+/, $header;
        pop @head; # Remove Pxxxxx
        my $id = shift @head;
        my $name = join ' ', @head;
        # Match any non-whitespace characters after PDB; and before ;
        # |s - Treat the string as one long line
        # |g - Global..i.e. all matches
        # thanks!
        my @pdbs = $block =~ m|PDB; (\S+);|sg;
        my $data = { name => $name, id => $id, txt => $block,
                     order => $block_count++, matched => 0 };
        $table->{$_} = $data for (@pdbs);
    }
    warn "There are $block_count species\n";
    return $table;
}

# i started to adore this style of using subroutins
sub parse_pdb_list {
    my ($pdb_list) = @_;
    open my $fh, "<", $pdb_list or die "Unable to open '$pdb_list' : $!";
    my %pdbs;
    while ( my $line = <$fh> ) {
        chomp($line);
        my ($pdb) = split /_/, $line;
        $pdbs{$pdb} = $line;
    }
    return \%pdbs;
}
