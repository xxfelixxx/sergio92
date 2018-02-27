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
    my @link_data;
    # there is a handy-command for bouncing the parens...I have to look it up. ok
    # Hold ctrl and alt down, and hit n or p  C-M-n C-M-p
    # https://www.emacswiki.org/emacs/NavigatingParentheses
    # good..before doing lets just open pdb file 1A2C.pdb and go to link line..I can do it as well
# just remind me how
    # C-x C-f
    for my $line ( <$fh> ) {
      	  chomp( $line );

          # Shit seems like I haven't sent the version with modifications, but we will
          # completely change it anyway..
          # Ok..this initial script among 3 seems to be tricky..not much but in some cases
          # for this one we have to files to test : 1A2C.pdb and 1DWK.pdb.
          # what we have to add is one more condition.
          # so far we were matching HET and HETATM lines and the numbers of CON.
          # its fine but we will include one more line: ^LINK.
          # when we open pdb file and go to LINK line we see that on the certain columns
          # we have some names as well..
          # So we want to do the matching of the names that are in /^HET / $columns [1],
          # and matching of these columns in LINK lines.
          # If all of them are matching then move to another pdb file.
          # if some of them are matching..jsut don't include them in pdb_filename at the end.
          # let me try to copy here the loop I have tried so far..id I can..
          # ok
          # seems like I havent saved it -.-..anyway I did this

          # put col          .-.                           .-.
          # put .-. columns into and array @link_data and match it with the elements
          # from /^HET / lines $column [1]
          # so after the first LINK line, @link_data = ('TYS','GLU'
          #
          # so match them with names from /^HET / $columns [1]..i think these names are also
          # stored in het hash..
          # id they match..skip them and don't do any calculations (sum od CON) for them..
          # if all of elements from ^HET line matches..then skip pdb cus there is nothing to
          # calculate..
          # if only some of them match..then continue to check the second two conditions
          # for those that don't match..
          # and id conditions for those that are not matched are fulfilling conditions
          # then put them in filename (we already have this done..just have to add this first
          # matching condition..
          #
          # hi, sorry about that...
          # cmon man don't be sorry for anything..u are doing me a big favor for helping me
          # and beeing a person who I can learn from.. :)
          # can we do this tomorrow? Dont ask me that. Just say it I dont have time
          # right now, lets do it tomorrow :D
          # ok, thanks. No, thank u..do u know when approximately u will have some time?
          # how about 1pm? I have a meeting at 2 pm but after that are u free during the day? yes.
          # Great! Thank You very much felix lets save this changes and continue tomorrow then :) ok

          # LINK         N   TYS I 363                 C   GLU I 362     1555   1555  1.33
          # LINK         C   TYS I 363                 N   LEU I 364     1555   1555  1.29
          # LINK        NA    NA H 626                 O   LYS H 224     1555   1555  2.34

          if ( $line =~ m/^LINK/ ) {
              my @link = split ' ', $line;
              # then I used the substrings, jsut let me check in manual
              my $link_col1 = substr($line, 17, 21); # Are these documented somewhere? Yes, in pdb
              my $link_col2 = substr($line, 47, 51); # manual but lets print and check.
              push @link_data, $link_col1, $link_col2;
          }

          # Splitting each line that starts with /^HET /
          elsif ( $line =~ m/^HET / ) {
              my @columns = split ' ', $line;

              # Move to the next line if last element of @columns array
              # has a value less then 6.
              next if $columns[-1] < 6;

              # If there is a hit then remember its names,
              # that are presented as the second element of an array.
              $hets{ $columns[1] }->{ heavy_atoms } = $columns[-1];
          }
          #then here I tried to do the matching like:
          # you can't put code here, you are between the if/elsif blocks
          # that what I had problem with..i cannot do this before and if I do this
          # outside the loop like at the end then it requires explicit package etc..errors
          elsif ( $line =~ m/^HETATM/ ) 
	{
        my @cols = split /\s+/, $line;
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
    } # end of massive if/else chain
          foreach (@link_data){
              if (1) {
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

