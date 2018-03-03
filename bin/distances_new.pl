#!/usr/bin/env perl

#------ perl pragmas
use strict;
use warnings;

#------ perl Modules
use File::Glob;
use Getopt::Long;

#------ Constants
use constant DEBUG   => 1; # 0 = off, 1 = on
use constant DIR_COV => 'covalently_bound';
use constant DIR_2_4 => '2_4';
use constant PERCENT => 70;
#----------------

my $percent = PERCENT;
my $verbose;
GetOptions("percent=i" => \$percent,
            "verbose"  => \$verbose)
    or die("usage: $0 [ --percent=70 ] [ --verbose ]\n");


debug("START\n");
create_subdirs();

my $text_data = get_all_text_data();
my $atoms = parse_all_pdbs();

for my $txt_file ( sort keys %$text_data ) {
    for my $pdb ( sort keys %$atoms ) {
        calculate_ligand_distances($txt_file, $pdb);
    }
}

debug("FINISH\n");
exit 0;

#--- Subroutines (functions)

sub ltrim
{
	my $string = shift;
	$string =~ s/^\s+//;
	return $string;
}

# Ok I think everything is fine overall just here to make some modifications and we can use file
# 1A2C.pdb for testing since all of his txt files are transfered to 2-4 fodler and should be
# in 0-2 for sure..so thats what I didnt understand why..ok so

# Just give me 1 min.
# So the way we are doing it now:
#
#one txt file

# HETATM1 > with all protein ATOM (if 1000) from pdb > 1000 results > meets 0-2..break loop move
# HETATM2 > -||-
# HETATM3 > -||-
# and so on

# so we are also breaking out of loop if the result is alsobtw 2-4.. so the problem is
# that if for each calculation between atoms (result 1000) first result is 3.1234 then it will
# immediately break out of the loop and move file to 2-4 folder..although result 545 may be
# 1.3453, but this file should have
# been moved to 0-2 folder then.

# So I am thinking..maybe to put it into a seperate loops or to apply this logic:

# I have an idea....instead of attempting to move the file inside this loop,
# why not just store which folder you would move it to, and then after all of the txt
# lines, pick the winning folder. So something like..memorizing file moving paths and then
# picking up folder files to be moved? yes. so instead of having a side effect, i.e.
# moving files, this function could just return the folder name, and we could store the
# best one for each pdb file
# just need to remove move_file logic, and have it return a folder id instead.
# I see it very much makes sense..jsut one thing..how to decide which folder is the best one..
# because we are not searching here and picking best folder..we just want to know how far away
# is ligand (small molecule sclosely binded to the protein) from the protein by calculating his
# distances. Since each txt file correspond to one ligand (or same ligand but differently
# positioned) then I don't know if it makes sense..many ligands will go to all three 2-4, 4-5, 5-6
# folders becase they are very close..but not many will end up in covalently_bound folder.

# So basically..its a bit messy but if we can say:
# Do whole calculation (btw all ligand and protein atoms) and check if it is 0-2..here we can
# break the loop when it is calculating HETATM1>all protein ATOMs(1000)..then if it meets 1.3123
# as a result while calculating HETATM1 and 554 ATOM of the protein..then we should break it and
# move to HETATM2> all protein ATOMs..
# same should be done for 2-4 4-5 5-6 but here instead of writing 3 seperated loops and doing sam
# calculations 4 times..maybe we can memorize it somehow....and we can also include braeking loop
# but when it meets all three ranges (2-4,4-5,5-6)..

# And as weel, we put that pdb file also has to be moved to covalently_bound folder, but we
# only want it to be moved to 2-4 range and nowhere else (id some txt filess are moved as well)..
# I have tried to change it by deleting $pdb_file but I made some mess a bit..

# I'm actually not at all clear about what you want to do here...
# So, briefly..

# one folder with 3 txt files and one pdb file
# txt file : HETATM lines (usually not more then 20)
# pdb file : Atom lines (usually few thousand)
# we have extracted distances and set the formula for calculation

# we want to check the distances between each ligand atoms HETATM and all protein atoms ATOM

# I know that...I am not sure what you want to change from the current behavior.



# Ok, here script is working great just to make some small changes in loops and to remove
# som stuff
# First: we dont need calculations and results and files to be moved to folders 2_$ an 4_5
# so if we can skip these calculations and moving files so to make script more faster
#
# skip everything?  oryes .just .so we just need calculations..results..moving files for
# fodlers cov_bound and 2_4
# ok...that's easy...that should do it. YeaH
# last thing for now is to modify loop..

sub calculate_ligand_distances {
    my ($txt_file,$pdb_file) = @_;

    debug("Calculating distances between $txt_file and $pdb_file");
    my $count_2_4 = 0;
    # counting the number of ligand rows for eaxh txt file
    my $ligand_rows = scalar @{ $text_data->{$txt_file }};
    # here LIGAND_ROW corresponds to each ligand row..each hetatm line? y
    # Ok here we are starting with first line of first txt file withing a folder
    # and calculating distances between this line and all ATOM lines from pdb file

    # So here..important in terms of my understanding
    # we look and first row of ligand file and then calc dist between all prot atoms
    # we first check 0_2 or cov_bound condition in the result..if yes..we move text file
    # and we continue to calc distances for second row and to search for the same file
    # ranges between 2_4, right?



    # Ok so everything is fine in terms of overall logic but just some changes have to be made.
    # we have a script that does this:

    # Calc dist between 1 lig atom to all protein atoms > from the result of this calculation calculate the perc
    # of those that are in tange 2-4. if the perc is 70% or more > move to next file.

    # We want to change it to this:
    # Calc dist between 1 lig atom and all protein atoms at the time > if just one result appears to be in range
    # of 2-4 break out of the loop for this 1 lig_all prot atoms calculation and move to the next ligand atom >
    # mark somehow that this ligand atom had met result in this range.move to another atom
    # > lig atom 2 - to all prot atoms > calculate dist > if 1 result is in range 2-4..break out of the loop> move
    # to another atom...but memorize that lig atom 2 gave result within this range.
    # lig atom 3 .......
    # if there are 10 lig atoms..if 7 of them (70%) gave result within the range of 2-4 then move this file to
    # folder 2_4 and ....

    # I think, I understand
    # So we have $count_2_4++ as long as there are any ...., but ok, can short circuit.
    # That should do it. Yes, lets try..so at the end it count how many ligand atoms had the result 2-4 and checks
    # perc if 70 % of ligand atoms had this percentage and then it moves the file..i guess this will be very fast
    # because in 90 percent of the cases lig atoms will have this range..so it will break everytime and make
    # script much faster..

  LIGAND:
    for my $ligand ( @{ $text_data->{$txt_file} } ) {
        my @distances;

        # Calculate all distances between one ligand row and all protein? rows
      ATOM:
        for my $atom_coord ( @{ $atoms->{$pdb_file} } ) {
            my $ligand_coord = $ligand->{ligand_coord};
            my $dist = distance( $atom_coord, $ligand_coord );
            push @distances, $dist;
            if ( 0 <= $dist && $dist < 2 ) {
                move_file( $txt_file, DIR_COV );
                return; # Stop processing this file
            }

            if ( 2 <= $dist && $dist < 4 ) {
                $count_2_4++;
                last ATOM;
            }
        }
    }

    # After all rows processed
    my $cutoff = $percent / 100;
    my ($p2_4) = $count_2_4 / $ligand_rows;

    print "Percent for 2_4 is " . int( 100 * $p2_4 ) . "\n";
    
    if ($p2_4 > $cutoff) {
        move_file( $txt_file, DIR_2_4 );
    } else {
        debug("Not good enough to move to 2_4...skipping");
    }
}
# we added this subroutine last time..and now we have find_btw and any_btw..we used any_btw for
# loop where we calculated distances within 0-2 range and we used find_btw for all other ranges..
# since we dont care what number it is, we care about range so shouldnt we use only once of these?
# like any_btw? Its opposite tough..ultimately, this is your logic, and it has to make
# sense for you, so you can defend it.

# i am having a hard time understanding whats the difference btw find_btw and aby_btw?

# one returns all of the matches, the other returns the count ( 0 if none, > 0 if some )
# so you could use it for boolean logic, i.e. if (any_between(...)) { ... }..now I see
# Thanks travis!

sub any_between {
    my ($min, $max, $array_ref) = @_;
    my $n = scalar @$array_ref;
    return 0 unless $n > 0;

    my @match = find_between( $min, $max, $array_ref );
    my $n_match = scalar @match;
    return $n_match;
}

sub parse_pdb {
    my ($pdb) = @_;
    debug("Working on $pdb...\n");
    open my $fh, "<$pdb" or die "Unable to open '$pdb' : $!";
    my @atoms;
    while(my $line = <$fh>) {
        chomp($line);
        if ( $line =~ /^ATOM/ ) {
            my $atom_row = parse_row($line);
            push @atoms, $atom_row;
        }
    }
    return \@atoms;
}


# Here we are just grab(b)ing rows from the text files where are ligand coord..

sub get_text_data {
    my ($txt_file) = @_;
    open my $fh, "<", $txt_file or die "Unable to open '$txt_file' : $!";
    my @ligands;
    while( my $line = <$fh> ) {
        chomp($line);
        debug("$. : $line\n");
        if ( $line =~ m/^HETATM/ ) {
            my @lig_atoms = split '\t', $line;
            # so here we are using function parse row to relate to only those values
            # that are in the 6..7..8 columns..
            # yes, it returns [ x, y, z ]
            # and it hides the implementation / validation details
            # so you can think about the bigger picture
            my $lig_coord = parse_row($line);
            # here we are pushing values of lig_coord into an array @ligands
            push @ligands, { ligand_coord => $lig_coord };
        }
    }
    # This returns and ordered (file order) array of ligand coordinates inside hashes
    # [ { ligand_coord => [x0,y0,z0] }, { ligand_coord => [x1,y1,z1] }, ... ]
    # I see, if we didn't use it..we could have ended up with messed..without order?
    # An array maintains order, a hash does not
    # We don't have to do it this way, could have just returned [ [x0,y0,z0], [ ], [ ], ... ]
    # Or even [ x0, y0, z0, x1, y1, z1, ... ]
    # It is untimately a design choice, that hopefully leads to easier to read/debug code
    # I see, lets move to the bottom because in sub process_pdb we are using more functions..
    return \@ligands;
}

# Ok, since protein and ligand atom coordinates are placed in the same columns, we can
# write subroutine to extract these values (coordinates)

sub parse_row {
    # TODO: Use an existing library to parse these files
    # How do we know what are the values of the row?
    # Here I think I get it we only declared @rows..and later we are picking up specific columns
    # Actually, $row is just the txt of the line
    my ($row) = @_;
    # Splitting each row based on its whitespace
    # Split on whitespace
    # Giving the values to each coordinate
    # Map function..
    # perldoc -f map
    # Map is like a for-loop that returns values
    # You read it from the right to the left
    # Example:
    # my @doubles = map { $_ * $_ } ( 2, 4, 6 );   # 4, 8, 12
    #
    # Read: take (2,4,6) run it through $_*$_ and map the results into @doubles
    # What are $_*$_ then here?
    # So $_ is the perl 'topic', 'default' variable
    # Map takes each number, assigns it to $_, evaluates what is inside the {..} and spits
    # out the result
    #
    # Equivalent to:
    # my @doubles;
    # for ( 2,4,6 ) {
    #     push @doubles, $_ * $_;
    # }
    # I see..so here we are taking each value of the splitted rows and assigning it to the
    # x,y,z coordinates?
    # only for columns 6,7,8.

    # Here I have made some changes..
    # so substr is dangerous....if you get the indexes wrong...yes I know..but after
    # checking it on my test files (108 files) it appears to be ok because each column
    # surely starts at the place i input (pdb file manual) but some of them are merged..
    # so I think I won't be having a problem with that because of the leading trim..
    # I couldn't think of any other way to delete all white spaces and to keep indexes correct.
    # ok.... I wouldn't do it this way, because ther is a risk that some other pdb file
    # has extra/missing space....the problem really is...it will work, i.e. not complain
    # even if the data are garbage...yeah I see..i will have to check it while running it on 60k.

    my $x_space = substr $row, 30, 8;
    my $x = ltrim ($x_space);
    my $y_space = substr $row, 38, 8;
    my $y = ltrim ($y_space);
    my $z_space = substr $row, 46, 8;
    my $z = ltrim ($z_space);
    debug("(x,y,z) = ($x,$y,$z)\n");
    for ($x, $y, $z) {
        # You can continue lines that are long onto the next line
        # so the
        # die ....
        #     unless ...
        # is a very common perl idiom
        # Ok so here we are checking if all coordinates have three decimal no.? yes
        # Ok so I understand it
        die "Invalid coordinate '$_' from line: \n'$row'\n"
            unless m|^-?\d+\.\d{3}$|; # 3 decimal places possibly negative
    }
    return [ $x, $y, $z ];
}

sub find_between {
    my ($min, $max, $array_ref) = @_;
    # [ 0, 1 ) i.e. closed min, open max interval

    # perldoc -f grep
    # grep is similar to map, in that it iterates over a list
    # grep is a filter, it only lets the elements which evaluate to True pass through
    # What we were evaluating here?
    # Let $min = 3, $max = 7, $array_ref = [ 1,2,3,4,5,6,7,8,9 ]
    # => @results = ( 3,4,5,6 )
    # And these number are distances results? Can be anything..ok we probably used this
    # subroutine while we were moving files to a folders...maybe ..but that detail
    # is not important here...then why do we have to take values that are btw min and max?
    # should we use here $min >=? no..unless that makes sense to you...
    # you go through 0-2, 2-4, etc. in increasing order...but if you want _anything_
    # less than some number, then change it to 0 <= $_
    my @results = grep { $min <= $_ && $_ < $max } @$array_ref;
    return @results;
}

# Not that rarely when pdb file has beeing moved, he moved to some directory but there couldnt be
# found his copy in the original folder?
# It means it got processed already. Ok. so it actually stays in a original folder until  all
# calculations are finished and then he is beeing moved?
sub move_file {
    my ($file, $dest_dir) = @_;
    print "Moving $file to $dest_dir\n";
    if ( -f "$dest_dir/$file" ) {
        print "--> Already moved to $dest_dir\n";
        return; # Should never happen
    }

    for my $dir ( DIR_COV, DIR_2_4 ) {
        if ( -f "$dir/$file" ) {
            print "--> Sorry, you already moved it to $dir\n";
            return; # Should never happen
        }
    }

    rename $file, "$dest_dir/$file"
        or die "Unable to move $file to $dest_dir : $!";
}

# This one I maybe had the hardest time understanding :P
# How do we know that $v1 is this..
# Again, a design decision, because in general references are easier to deal with in perl
# and this is just a function inside this script....so the consumer can just check to see
# what it takes....if it were a function inside a Library (aka Module aka Package)
# We would need to document it better, and validate it better, and honor the contract
# that we decide upon, i.e. don't change what the inputs can be once other scripts depend
# on this function
# In perl, in the beginning, you learn all about scalars $foo, arrays @bar, and hashes %qux
# But in practice, it is easier often to just deal with $foo, $bar_array_ref, $qux_hash_ref
# Because often times, if you have a nested datastructure (like a tree) you want to create
# it on the fly, with anonymous array and hashrefs (annonymous, i.e. no variable name)
# Good question...
# Input: $v1 : [ x0, y0, z0 ]
#        $v2 : [ x1, y1, z1 ]
# Output: Sqrt of the squared differences, aka Distance
sub distance {
    my ($v1, $v2) = @_;

    die "Pass in array references!"
        unless ref $v1 eq 'ARRAY' and ref $v2 eq 'ARRAY';

    # Get vector lengths
    my $len1 = scalar @$v1;
    my $len2 = scalar @$v2;

    # Check that they are the same length
    $len1 == $len2
        or die "Invalid vectors [ " . @$v1 . " ] and [ " . @$v2 . " ]";

    # For each component (x,y,z) calculate the squared differences
    # and add it to $squared_differences
    my $squared_differences = 0;
    # this loop looks a bit confusing for me ..
    # for ( 0, 1, 2 ) { ... }
    # but would also work for N-D vectors
    # Perl arrays are 0-indexed, so $len1-1
    # Could also use something like $#$v1 ( but that is really ugly )
    # Array @foo has last index $#foo
    # I see it now..$ii is refering to the components of $v1 and  $v2 and we are reading
    # it from 0 (first element) to the last one..
    for my $ii ( 0 .. $len1-1 ) {
        # $v1 and $v2 are Array References, so to get at the elements, use the ->
        # @foo is an Array
        # @foo = (1,2,3); $foo[2];   # is 3
        # $bar is an Array Reference
        # $bar = [1,2,3]; $bar->[2]; # is 3
        $squared_differences += ( $v1->[ $ii ] - $v2->[ $ii ] ) ** 2;
    }

    # Take the square root of $squared_differences and return it
    return sqrt($squared_differences);
}
# To search backwards....Ctrl-r
sub debug {
    print join(' ', 'DEBUG: ', @_) if DEBUG or $verbose;
}

sub create_subdirs {
    for my $dir ( DIR_COV, DIR_2_4 ) {
        next if -d $dir;
        print "Creating dir: $dir\n";
        mkdir $dir or die "Unable to create '$dir' : $!";
    }
}

sub get_all_text_data {
    my $text_data = {};
    for my $txt_file ( glob '*txt' ) {
        $text_data->{ $txt_file } = get_text_data($txt_file);
    }
    die "No text files found!" unless keys %$text_data;
    return $text_data;
}

sub parse_all_pdbs {
    my $atoms = {};
    for my $pdb_file ( glob '*pdb' ) {
        $atoms->{$pdb_file} = parse_pdb($pdb_file);
    }
    die "No PDB files found!" unless keys %$atoms;
    return $atoms;
}
