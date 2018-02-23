#! usr/bin/env perl

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
for my $pdb ( glob '*pdb' ) {

	#printf "# %s\n", $pdb;
	open my $fh, "<", $pdb;

	my %hets;
	my @suf;

        for my $line ( <$fh> ) {

      	  chomp( $line );

	  # Splitting each line that starts with /^HET /
          if ( $line =~ m/^HET / ) {
              my @columns = split ' ', $line;
	      #print "$columns[-1]\n";
	      # Move to the next line if last element of @columns array
              # has a value less then 6.
              next if $columns[-1] < 6;
	      # If there is a hit then remember its names, that are presented as the second element of an array.
              $hets{ $columns[1] } = $columns[-1];
              }

	# Splitting each line that starts with FORMUL.
        # 4th column may have spaces in it, so its lumped together.
        elsif ( $line =~ m/^FORMUL / ) {

            my @cols = split /\s+/, $line, 4;
	    print "$cols[-1]\n";
	    # move to the lines of FORMUL that have a same name presented as in $hets
            next unless $hets{ $cols[2] };
	    # Initialize these to zero _before_ extracting actual counts
            my %letters = ( C => 0, O => 0, N => 0 );
	    # Matching letters that can be followed by digits in the formula.
            while ( $cols[-1] =~ m/([CON])(\d+)/g ) {
		
                $letters{$1} = $2;
		#print "$letters{$1}\n";
            }

            my $con = $letters{"C"} + $letters{"O"} || $letters{"N"};

            if ( $letters{"C"} > 2 && $con >= 6 ) {
                push @suf, $cols[2];
            }
        }
    }

    if ( @suf ) {
        #print " ", join( "_", $pdb, @suf ), "\n";
	#system ("mv $pdb $pdb,@suf so");
    }
}
