# ok, if u dont remember let me copy the email I have sent u yesterday, we will need to change I think first two subroutines and before subroutines code..one sec
# you need to work on explaining things with fewer words....# yeas I know my exmplanations are wierd confusing and bad
# Do you have a teddy bear?
# ahah no, why?
# at MIT, in the computer lab, they setup a teddy bear, just outside the
# office of the support staff.  If someone (a student) has a question,
# they are to ask the teddy bear first.  The act of explaining it
# to anyone (even a teddy bear) served to get people clarify what they
# were trying to figure out, so if they didn't figure out the problem
# while talking to the teddy bear ( which would often happen ), they 
# could better explain it to a real person, since they had some practice.
#
#Hm, very interesting..honestly it makes sence to some extent.
# It is very easy for someone to answer questions which are very specific
# and generally have an answer, but to ask such questions, you have to
# cut it back to just the essential thing (it is a skill, it takes practice)
# it has nothing to do with your level of english, its more a thought
# process thing

# 1 Lig_atoms to all protein atoms (opposite logic we did)
# # really? Yeah I guess we calculated distances between protein atom1 and all lif_atoms..then prot_atom2 and all lig_atoms..etc
# #ok, lets do that first.

# So.... if 0-2 move it to 0-2 folder and braek out of the script (forget about the details)
#        elsif 2-4 (only once) break out of the script and remember something

# 

# Hey Felix,

# I just realized that the thing with percentage we didn't assigne
# well because I confused it a bit more and thats why it wasnt giving
# me correct result..

# The thing is that we calculated percentage of the result of each
# distance calculation..and we should do like this (if we have 10
# ligand atoms):

# 1st CALCULATION > Calculate ligand_atom1 with all protein_atoms> if
# it appears only once that distance is between 0-2 brake out of the
# script and move it to the folder..if it appears only once that dist
# is between 2-4 then break out of the script and memorize it. 

# 2nd CALCULATION > Calculate ligand_atom2 with all protein_atoms> if it
# appears only once that distance is between 0-2 brake out of the
# script and move it to the folder..if it appears only once that dist
# is between 2-4 then break out of the script and memorize it.  .  .
# .

# 10th CALCULATION > Calculate ligand_atom10 with all protein_atoms>
# if it appears only once that distance is between 0-2 brake out of
# the script and move it to the folder..if it appears only once that
# dist is between 2-4 then break out of the script and memorize it.

# And here..if 70 percent of number of ligand atoms (there is 10
# ligand atoms, so 7) had once result between 2-4 (like above when we
# break out of the script) then move it to 2-4 folder. Then we dont
# specifically need folders 4-5 and 5-6.

# This will make script work much faster if we break out of the loop
# like this.

# I will make changes to the script during the day. I guess I have to
# make some changes in first two subroutines (process_result and
# decide_which_text_files_should_move).

# Will u have one hour later so we can go trough it together?

# Best, Srdjan





#!/usr/bin/env perl

#------ perl pragmas
use strict;
use warnings;

#------ perl Modules
use File::Glob;
use Getopt::Long;

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
use constant DEBUG   => 0; # Set to 1 for lots of detail
use constant DIR_COV => 'covalently_bound';
use constant DIR_2_4 => '2_4';
use constant DIR_4_5 => '4_5';
use constant DIR_5_6 => '5_6';
use constant PERCENT => 70;

#----------------
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
        calculate_ligand_distances($txt_file, $pdb);
    }
}

#process_results( %atoms );

debug("FINISH\n");
exit 0;

#--- Subroutines (functions)
# The idea is to break up your program into smaller manageable (testable hopefully)
# chunks that you can more easily reason about...

sub calculate_ligand_distances {
    my ($txt_file,$pdb_file) = @_;
    my ($count_2_4,$count_4_5,$count_5_6) = (0,0,0);
    my $ligand_rows = scalar @{ $text_data{$txt_file }};
  LIGAND_ROW:
    for my $ligand ( @{ $text_data{$txt_file} } ) {
        my @distances;

        for my $atom_coord ( @{ $atoms{$pdb_file} } ) {
            my $ligand_coord = $ligand->{ligand_coord};
            my $dist = distance( $atom_coord, $ligand_coord );
            push @distances, $dist;
        }

        my @less_than_2 = find_between( 0, 2, \@distances );
        if ( scalar @less_than_2 ) {
            move_file( $pdb_file, 
                       scalar @less_than_2 == 1 ? DIR_COV : DIR_2_4 );
            next LIGAND_ROW;
        }

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
    }
    if ($dest) {
        move_file( $pdb_file, $dest );
        move_file( $txt_file, $dest );
    }

}

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
        if ( $line =~ /^ATOM / ) {
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
            # here we are pushing values of lig_coord into and array @ligands
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
    my (@row) = split /\s+/, $row; # Split on whitespace
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
    my ($x,$y,$z) = map { sprintf("%0.3f", $_) } @row[6..8];
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
    my @results = grep { $min <= $_ && $_ < $max } @$array_ref;
    return @results;
}

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
