#!/usr/bin/env perl

# Ok while going trough the script I had some misunderstandings so if we can go trough it.
# Instead of using space to split the columns I have changed it to substrings because some
# columns are merged..i have also included leading trim in case line starts with whitespace

# you know, you can split on more than one character.... split /\s+/ to split on space_S_
# foo    bar     baz => ( 'foo', 'bar', 'baz')
# documentation: perldoc -f split
# yes I know that I can split on space and one a character as well..but here I think we had a
# problem with that becasue in some pdb files columns are merged. So I think substring is a good
# choice.

# Apart from that..i want to go trough final loops while calculating distances..i wanted previousl
# to change it and I didn't make it because I made some mess :P
# also while running a script it appears becasue we use move_file subroutine..it appears that
# not all pdb files stay in their original folder.
# lets go step by step, ok? ok

#------ perl pragmas
use strict;
use warnings;

#------ perl Modules
use File::Glob;
use Getopt::Long; # what do we use this one for?

# Ok here in this script main point are subroutines or functions taht we are using and there are
# few of them..

# Why do we here use constants, been search for meaning of it..for example..why we didnt use mkdir
# and we used this and bellow we made directoreis?
#
# So...why do this? you don't have to, but it is a good practice to do so
# It doesnt makes any changes, but this way is more accurate?
# No...in some ways it is easier to read
# It saves you from a certain class of bugs
# for example, in you don't 'use strict'
# Then $foo = 2;....later $bar = $fo0; # compiles just find...$foo = 2, but $fo0 = undef
# now we have a subtle bug
# But if we mistype a constant, we get a compile time error
# it makes code easier to read, in some cases, and it lets you know that the thing is
# never going to change
# I see, ok

# Can we first start with commenting subroutines and then move to the calculations?
# ok

#------ Constants
#what DEBUG => 0 means?
use constant DEBUG   => 0; # Set to 1 for lots of detail
use constant DIR_COV => 'covalently_bound';
use constant DIR_2_4 => '2_4';
use constant DIR_4_5 => '4_5';
use constant DIR_5_6 => '5_6';
use constant PERCENT => 70;


# Problem1: in some examples pdb is beeing moved to covalently_bound and they shoud be moved only
#           to 2-4 folder if they are moved.

# Problem 2: calculating distances in some not correct in some examples like 1A2C.pdb txt files
#            should be moved to covalently_bound, but they are not.

# LIGAND_ROW, maybe to copy files insted of moving them


#----------------

# Command line options --percent=20 --verbose
# It would be usefule to have a usage() section (i.e. --help)
# It is considered good practice to have scripts not just run, but to take options...
# I see..what we were relating verbose to?  # search for $verbose and find out. I forgot its not
# Ctrl-s ( you can erase as well in the minibuffer (the bottom line below the purple line))
# Ctrl-g to get you out of trouble. Yeah. Soo, verbose we used just to turn on debugging lines. Ok
my $percent = PERCENT;
my $verbose;
GetOptions("percent=i" => \$percent,
            "verbose"  => \$verbose)
    or die("Error in command line arguments\n");

debug("START\n");

# Create subdirectories
for my $dir ( DIR_COV, DIR_2_4, DIR_4_5, DIR_5_6 ) {
    next if -d $dir;
    print "Creating dir: $dir\n";
    mkdir $dir or die "Unable to create '$dir' : $!";
}

# Collect all of the Text file data into memory
# What does it mean into memory? Into %text_data. Ok
my %text_data;
# Here we are refering to all txt files
for my $txt_file ( glob '*txt' ) {
    # Here we are refering only to coordinates of text files, right? # maybe...see get_text_data()
    # End of get_text_data are ligand coordinates so I guess we do...yup
    # You may wish to _rename_ the subroutine to something more descriptive....
    $text_data{ $txt_file } = get_text_data($txt_file);
}
die "No text files found!" unless keys %text_data;

# For each PDB file, store the ATOMs
my %atoms;
for my $pdb_file ( glob '*pdb' ) {
    $atoms{$pdb_file} = parse_pdb($pdb_file);
}
die "No PDB files found!" unless keys %atoms;

for my $txt_file ( sort keys %text_data ) {
    for my $pdb ( sort keys %atoms ) {
        # After every pdb, but remember, you are repeating pdbs over and over,
        # for each $txt_file....you could skip this step if the pdb has already
        # been moved by checking if the pdb file is still in its original location...I see
        # lets keep it like this.
        calculate_ligand_distances($txt_file, $pdb);
    }
}

#process_results( %atoms );

debug("FINISH\n");
exit 0;

#--- Subroutines (functions)
# The idea is to break up your program into smaller manageable (testable hopefully)
# chunks that you can more easily reason about...


# you don't need the prototype ($), unless you know what you are doing...and you don't
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

sub calculate_ligand_distances {
    my ($txt_file,$pdb_file) = @_;
    my ($count_2_4,$count_4_5,$count_5_6) = (0,0,0);
    # counting the number of ligand rows for eaxh txt file
    my $ligand_rows = scalar @{ $text_data{$txt_file }};
    # here LIGAND_ROW corresponds to each ligand row..each hetatm line? y
    # Ok here we are starting with first line of first txt file withing a folder
    # and calculating distances between this line and all ATOM lines from pdb file
  LIGAND_ROW:
    for my $ligand ( @{ $text_data{$txt_file} } ) {
        my @distances;

        for my $atom_coord ( @{ $atoms{$pdb_file} } ) {
            my $ligand_coord = $ligand->{ligand_coord};
            my $dist = distance( $atom_coord, $ligand_coord );
            push @distances, $dist;
        }

        # why do we use here find_between and not find_any ?
        # we just want to check if the result of each calc is within this range
        # we can change it to find_any, to make it more consistent
        # should here be any_between instaed of find_any? yes


        # here we want onlt txt file to be moved not pdb file as well, so if I remove $pdb_fil
        # it gives me some errors in subroutine move_file...what error? something related
        # to the destination..and implies it to lines of move_file subroutine..unclear
        # ok, lets just delete $pdb_file so lets see what we will get after running it, ok?y

        # that does not make any sense, what file are you moving? here nither..have to put
        # txt file. thanks :) ok
        # So here..in the first loop will it go trough all calcuations of one txt-pdb file
        # until it finds 0-2 and then if not it tries to find other ranges or all at once?
        # after each calc ligand line vs all pdb lines, it sees if any dirs are appropriate..
        # Ok I see, and here it only moves txt files 0-2 if they are within this range and
        # other results it just memorize somehow?
        # it counts
        # So here we are moving to lig_atom2 - all protein atoms? basically its like
        # a goto...so go to the LIGAND_ROW label, i.e. skip the rest of the counting
        # for the other folders.
        # So it will seach for all LIGAND_ROWs? and we have to check for each ligand row range
        # 0-2 as well..because this range can be result at calculations btw lig_atom5-allprot
        # atoms..yes..even though we already moved the file...(we have the data in memory) ok

        # clearer? yes. thank u felix :)
        my $n_less_than_2 = any_between ( 0, 2, \@distances );
        if ( $n_less_than_2 ) {
            move_file(  $txt_file,
                        $n_less_than_2 == 1 ? DIR_COV : DIR_2_4 );
            next LIGAND_ROW;
        }
        # here we are counting the result to be btw different ranges , counting # lines in txt
        # file that match these criteria, we use these counts to figure out the cutoffs...
        # percents..yes I see..are we starting these countings and calculations from the
        # lig_Atom1 - all protein atoms? yes. I see. I think all these parts should be good
        # just one think what kept me condusing..is moving of this pdb file..
        # it condused me moving it to 0-2 but now since we changed it it shouldnt be a problem..
        if ( any_between( 2, 4, \@distances ) ) {
            $count_2_4++;
        }

        if ( any_between( 4, 5, \@distances ) ) {
            $count_4_5++;
        }

        if ( any_between( 5, 6, \@distances ) ) {
            $count_5_6++;
        }
    }

    my $cutoff = $percent / 100;
    my ($p2_4, $p4_5, $p5_6) = map {
        ($_ / $ligand_rows) 
    } ( $count_2_4, $count_4_5, $count_5_6 );

    print "Percent for 2_4 is " . int( 100 * $p2_4 ) . "\n";
    print "Percent for 4_5 is " . int( 100 * $p4_5 ) . "\n";
    print "Percent for 5_6 is " . int( 100 * $p5_6 ) . "\n";
    
    my $dest = '';
    if ($p2_4 > $cutoff) {
        $dest = DIR_2_4;
    } elsif ($p4_5) {
        $dest = DIR_4_5;
    } elsif ($p5_6) {
        $dest = DIR_5_6;
    } else {
        # wait..maybe we shouldnt go with 5-6 and 4-5 because u see 
        # From the previous example all were above 70 percent so 
        # all of them cant be moved so maybe just to comment on it 
        # and one more simple thing..is if there are more txt files (mostlythe case)
        # and it works first with one of them..and it moved pdb file as well..then the 
        # calc within other txt files and pdb (moved) file wont be possible..so
        # maybe just to copy it and then I will do sort -u in the 2-4 direcotry if there
        # are more identical pdb files..what do u say?
        # you have everything in memory, you can move things, it won't matter.
        # I think I need to stop...perhaps you could continue.
        # we are almost finished..can we try to run this on our examples?
        # I rhink we ddid 99 percent?
        # here after all these comments this else loop stays empty and it doesnt seems to be a
        # problem solved. :D u make me laugh now :D
        debug("Hit the else block, wtf?"); # do we need this loop although its empty?
        # it is not a loop, it is a block, specifically an else-block, yes you need it
        # not because it won't run, but because you will introduce bugs if you don't check
        # your else-blocks. Yeah I see but before there were no debugs we put it now
        # so apart from that is there something else important? ? what are you asking?
        # we put debug line today so while running it last time this block was empty
        # it didn't give any errors but it was empty so we could have deleted it, but now we
        # need it, right?  it is coding style, there are lots of things which are not
        # strictly necessary, but you do because they help you later...you haven't been burned
        # by a missing else block before, so you don't know to do this...of course, thats why I
        # ask ..know that there must be something. :)
        # specifically in this code, it means that we didn't match any folders....the consequence
        # of which will be that the files don't get moved.....so when that happens, and you
        # scratch your head....and you turn on --verbose...you will see this wtf line...
        # and know what is actually going on....if it wasn't there, you wouldn't get any feedback
        # at all, and would have to manually try to debug it (maybe its not a bug...that's how
        # the data is...but it _feels_ like a bug because nothing happened...) I see.
        # thanks felix :) this style of programming is called 'defensive'. Pretty descriptive name
        # ok so I guess thats it..can we try to run it on 1A2C.pdb to see if it gives range 0-2?

        # Sure...
    }
    # here we are moving pdb file to all three directories? no, just the winning one.
    # which one is the winning one? whichever branch of the if/elsif/... above it hits.
    # we should onlt move it to 2-4 folder if percentage is matches..together with txt files
    # because if i have txt files in 2-4 folder without pdb then I have tochange it
    # and one more..for txt files if it picks up 4-5 or 5-6 to bw winning (first matched?) then it
    # move then to these folders..although relating to percetange it can also be moved to 2-4 and
    # it is not because its not the winning? yes, they are picked in order, if 2-4 then 2-4 else
    # if 4-5 then 4-5, else then ...etc you can change the logic, but that is the logic you wanted
    # so it first checks 2-4 fodler among these three? and then if notting to be moved there..
    # it checks 4-5 and 5-6 folders? yes, in that order.....
    if ($dest) {
        move_file( $pdb_file, $dest );
        move_file( $txt_file, $dest );
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
	    print "$x\n";
   	    my $y_space = substr $row, 38, 8;
	    my $y = ltrim ($y_space);
	    print "$y\n";
   	    my $z_space = substr $row, 46, 8;
	    my $z = ltrim ($z_space);
	    print "$z\n";
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
        return;
    }

    for my $dir ( DIR_COV, DIR_2_4, DIR_4_5, DIR_5_6 ) {
        if ( -f "$dir/$file" ) {
            print "--> Sorry, you already moved it to $dir\n";
            return;
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
