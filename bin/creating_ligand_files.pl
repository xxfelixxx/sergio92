#! usr/bin/env perl

# This script attempts to extract all ligand coordinates from pdb files into seperate txt files.
# Ligands are also seperated based on their chain and residue id.
# It uses ligands.txt file for matching.
# Input for this script are ligands.txt file and pdb file. 
# Output of this script will be multiple ligand files with coordinates. 

use strict;
use warnings;
use autodie;
use 5.010;
use List::MoreUtils qw( uniq );

sub debug { }

#Opening ligands.txt file
my $ligand_file = 'ligands.txt';
open( my $LIG, $ligand_file ) or die "Cannot open $ligand_file, $!";
debug("Reading ligands file: $ligand_file");
my %ligands_hash;
#Reading each line of the file
for my $ligand ( <$LIG> ) 
{
    chomp( $ligand ); # Remove trailing newline
    $ligands_hash{ $ligand } = 1;
}
close $LIG;
debug("Found ligands: " . join(',',sort keys %ligands_hash));

my %output_files;
my $is_in_ligands_txt = 0;

#Opening pdb file
for my $pdb ( glob '*pdb' ) 
{
    my %ligands_found;
    my $data_hash_ref;

    debug("-"x40);
    debug("Working on file $pdb");
    open my $fh, "<", $pdb;
    for my $line (<$fh>) 
    {
        chomp($line);
        if ( $line =~ m/^HETATM / ) 
	{
            $line =~ s|\s*$||;
            debug("--> Found an ATM line");
            my @cols = split ' ', $line;
            my ( $ligand, $chain_id, $res_no ) = ( $cols[3], $cols[4], $cols[5] );
            debug("--> Adding ligand $ligand to ligands_found hash");
           $ligands_found{ $ligand }++;
           defined $res_no
           or die "Unable to grok line: $line";
            
            # This works because perl automatically creates the missing
            # parts of nested hash (this is known as Autovivication).
            # The last part, the array is also created by the attempt
            # to push onto it, so perl assumes it should exist.
            push @{ $data_hash_ref->{$ligand}->{$chain_id}->{$res_no} }, $line;
	    #push @{ $data_hash_ref->{$chain_id}->{$res_no} }, $line;
        }
    }

    debug("Processing ligands");
    for my $ligand (sort keys %$data_hash_ref) 
    {
        1;
        $is_in_ligands_txt = defined $ligands_hash{$ligand} ? 1 : 0;
        debug("--> Ligand $ligand, is_in_ligands_txt = $is_in_ligands_txt");

        for my $chain_id ( keys %{ $data_hash_ref->{$ligand} } )
	{
            for my $res_no ( keys %{ $data_hash_ref->{$ligand}->{$chain_id} } )
	    {
                debug("------> Chain Id = $chain_id, Res No = $res_no");
                my @lines = @{ $data_hash_ref->{$ligand}->{$chain_id}->{$res_no} };
                if ( $is_in_ligands_txt and scalar @lines > 1 )
		{

                    # Output filename based on first ligand with $chain_id and $res_no combo
                    my $outfile = join( '#', $ligand, $chain_id, $res_no ) . '.txt';
                    my $nl = (scalar @lines);
                    my $nl_desc = "$nl line" . ($nl > 1 ? "s" : "");
                    debug("------> Appending $nl_desc to $outfile");
                    open my $out, ">> $outfile";
                    print $out "$_\n" for (uniq @lines);
                    close $out;

                    # Remove the lines so they don't get printed twice.
                    undef @{ $data_hash_ref->{$chain_id}->{$res_no} };
                }
            }
        }
    }
}

