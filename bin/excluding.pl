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

sub ltrim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	return $string;
}

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
          elsif ( $line =~ m/^HETATM/ ) 
	{
            my @cols = split /\s+/, $line,
	    $line =~ s|\s*$||;
            debug("--> Found an HETATM line");
	    my $type_space = substr $line, 17, 3;
	    my $type = ltrim ($type_space);
	    #print "$type\n";
   	    my $chain_space = substr $line, 21, 1;
	    my $chain = ltrim ($chain_space);
	    #print "$chain_id\n";
   	    my $id_space = substr $line, 23, 3;
	    my $id = ltrim ($id_space);
	    #print "$res_no\n";
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
	$data->{C} = {}; 
	$data->{O} = {};
	$data->{N} = {};
        my $con = $data->{C} + $data->{O} || $data->{N};

        if ( $data->{C} > 2 && $con >= 6 ) {
            push @suc, $het;
        }
    }

    if (@suc) {
        my $new_pdb = join('_',$pdb,sort @suc);
        print $new_pdb . "\n";
    }
}

