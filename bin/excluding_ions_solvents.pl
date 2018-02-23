#!/usr/bin/env perl

# Script attempts to filtrate all pdb files and to check and exclude 
# those who has only ions and solvents presented in their binding site.
# Ions are excluded by checking the number of heavy atoms to be
# more then 6, while solvents are excluded by checking the sum 
# of heavy atoms to be more or equal to 6.
# The new filenames created will be suitable as input for further commands.
#

use strict;
use warnings;
use autodie;

# Opening and reading each pdb file in a directory by using glob functions.
sub debug { }

my @pdbs = scalar @ARGV ? @ARGV : glob '*pdb';

for my $pdb ( @pdbs ) {

#	printf "# %s\n", $pdb;
	open my $fh, "<", $pdb;

	my %hets;
    my $last_hetatm;

    for my $line ( <$fh> ) {
      	  chomp( $line );

          # Splitting each line that starts with /^HET /
          if ( $line =~ m/^HET / ) {
              my @columns = split ' ', $line;

              # Move to the next line if last element of @columns array
              # has a value less then 6.
              next if $columns[-1] < 6;

              # If there is a hit then remember its names,
              # that are presented as the second element of an array.
              $hets{ $columns[1] }->{ heavy_atoms } = $columns[-1];
          }
          elsif ( $line =~ m/^HETATM/ ) {
              my @cols = split /\s+/, $line;
              my ($type, $chain, $id) = @cols[3..5];
              my $row_key = join(':',$type,$chain,$id);
              if ( defined $hets{ $type } ) {
                  if (not defined $last_hetatm) {
                      $last_hetatm = $row_key;
                  } elsif ( $row_key ne $last_hetatm ) {
                      # Declare the block finished
                      my ($block_type,$chain,$id) = split /:/, $last_hetatm;
                      $hets{$block_type}->{chain} = $chain;
                      $hets{$block_type}->{finished_block} = 1;
                      $last_hetatm = $row_key;
                  } else {
                      # Continuation of block
                  }

                  $hets{$type}->{rows}++;
                  next if defined $hets{$type}->{finished_block};
                  my $element = $cols[-1];
                  $hets{$type}->{$element}++; # Count
              } else {
                  # print "Skipping $type $chain\n";
              }
          }
    }

    my @suc;
    for my $het (keys %hets) {
        my $data = $hets{$het};
        my $con = $data->{C} + $data->{O} || $data->{N} || 0;

        if ( $data->{C} > 2 && $con >= 6 ) {
            push @suc, $het;
        }
    }

    if (@suc) {
        my $new_pdb = join('_',$pdb,sort @suc);
        print $new_pdb . "\n";
    }
}



#So script is working fine but I want to modify it in another way just for comparison reason..
# All steps until here are good. and here we will have to make some changes probably by using hash
# So, script so far (above) checks ^HET lines and then checks the last column if the number is <6
# it jumps over it and if not it keeps the names (three letter) of the molecules (ligands) into
# the hets. Ok next step was summing the number of CON from FORMUL lines, but now..
# search Ctrl-s
# HETATM 2418  C5  34H J   1      13.354 -20.706  25.121  1.00 29.23           C
# Splitting each line that starts with FORMUL.
# So, now instad of going to the formul line and checking if the name in hets matches with the
# second column of formula lines..we should read ^HETATM lines, match the name in hets with
# third element (4th column) of HETATM lines and then as this name appears the sam in the 4th col
# we should count the number of CON (last column) for that block. If the name that was saved in
# het is 34H then from this HETATM example it matches..and count the number of C0N in last column
# all the way untul 34H stops appearing in the 4th column.
# And again..same condition..id the number of C>2 and sum of CON >= 6 then put it in the filname
# we dont have to change these last steps..just the way we are counting atoms.

# Last thing is that 34H may appear in more then one block..so we just have to count the number
#of atoms in the last column (CON) within one 34H block..and same for all the others that are
# found in the het hash.
