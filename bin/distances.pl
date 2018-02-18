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
# The idea is to break up your program into smaller manageable (testable hopefully)
# chunks that you can more easily reason about...

# process_results
# Input: %atoms - a hash which has keys that are the pdb filenames
#                 with values the data results of calling process_pdb() on that file
# Output: None
#
# Side-Effects: Modifies %distances_by_text_file
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

        decide_which_text_files_should_move( $pdb_file, %distances_by_text_file );
    }
}

sub decide_which_text_files_should_move {
    my ( $pdb_file, %distances_by_text_file ) = @_;

    for my $txt_file ( sort keys %distances_by_text_file ) {
        my @distances = @{ $distances_by_text_file{ $txt_file } };  

        my @less_than_2 = find_between( 0, 2, \@distances );
        if ( scalar @less_than_2 ) {
            move_file( $txt_file,
                       scalar @less_than_2 == 1 ? DIR_COV : DIR_2_4 );
            next; # next text file
        }

        if ( percent_between( $percent, 2, 4, \@distances ) ) {
            # I wanted to ask u here something..
            # At the end..within each subdirectory I will have few directories and in some of them
            # ligand txt files will be stored..since I will only have to make use of those ligand
            # files that have distance between 2-4 I would have to extract them somehow..
            # In the final step of the whole dataset is I have to make a table..I will have to use
            # Orignial pdb files and to refer in the table only to those ligands taht are in 2-4
            # directory..
            # So I would have to say something like..if in each subdirectory..it happens that
            # some of the ligand txt files is beeing moved to 2-4 subdirectory, then move pdb file
            # as well..so at the end I can somehow from all subdirectories grep these pdb files
            # and maybe somehow make a list of filenames (pdbfile_name#ligand_name) or something
            # like that..At the end from all these pdb files..I am extracting only few lines from
            # from each of them (by using grep) and then making a table looking content..
            # The thing is that within each pdb file under lines that start with ^HETATM there are
            # all ligand names..but I would only have to take these names (files) that are in
            # in the 2-4 subdirectory and in the table only to refer to them..have to think
            #
            #So you want to summarize at the end?
            # Here on this step I can just include that if some of the ligand files are moved
            # to 2-4 subsubdirectory then to move orignial pdb file to that directory as well..
            # Then later..by using some other script I will have to think how to grep only those
            # pdb files that are in the 2-4 (sub sub)directory and somehow ..dont know how to
            # link them only with those ligand (txt) filenames that are in the same directory..
            # So at the end by using some other script to end up with a table that under
            # HETATM lines wont have all ligand names but only those that are found together
            # with pdb file in this 2-4 subdirectory..
            #
            # So , now if only one or more ligand txt files are moved to this directory, that will
            # directly move pdb file into that directory as well?

            # Need to verify we have a proper path here...but this would work.
            # Cannot verify without running it....to run it need some test files...
            # we can use the output of the previous script..so the output of the previous script
            # is input to this one :)
            # just over there we had 2 pdb files and more ligand files..maybe we can run
            # prevvious script just on one pdb file and run this script on the same pdb file
            # no thats fine i think..

            if ( -f $pdb_file ) {
                print "Moving PDB file $pdb_file\n";
                move_file( $pdb_file, DIR_2_4 );
            }
            move_file( $txt_file, DIR_2_4 );
            next;
        }

        if ( percent_between( $percent, 4, 5, \@distances ) ) {
            move_file( $txt_file, DIR_4_5 );
            next;
        }

        if ( percent_between( $percent, 5, 6, \@distances ) ) {
            move_file( $txt_file, DIR_5_6 );
            next;
        }

        # Fallback case
        print "Boo: no home for $txt_file....leaving it here\n";
    }
}

# For example this seems like it can be first one we made
# Here we are extracting atom coordinates from pdb file

sub process_pdb {
    # Here we are reading each pdb file to its end
    my ($pdb) = @_;
    debug("Working on $pdb...\n");
    open my $fh, "<$pdb" or die "Unable to open '$pdb' : $!";
    my @atoms;
    while(my $line = <$fh>) {
        chomp($line);
        if ( $line =~ /^ATOM / ) {
            # Ok next thing we will do is go to the parse_row subroutine and then come back here
            # yes...real code looks like this, it jumps around alot
            # Atom coordinates are beeing extracted
            my $atom_row = parse_row($line);
            # Here we are calculating distances between $ atom_row and ligands or?
            # 1 atom row vs All ligands
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
        # Array reference..here we are refering to each subelement of @ligands (worst explanation sorry :P
        # Yeah, so $ligands is an array reference...so here we iterate over each one
        # Hopefully the variable names make this all obvious..yes it makes :)
        for my $ligand ( @$ligands ) {
            my $lig_coord = $ligand->{ligand_coord};
            my $dist = distance( $atom_row, $lig_coord );
            push @lig_distances, { ligand_coord => $lig_coord, distance => $dist };
        }
        push @distances, { text_file => $txt, distances => \@lig_distances };
    }

    return \@distances;
    # Ok, here we are calculating distance between each ligand row and 1 atom row and under
    # @dinstaces are result, right? yes
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

sub percent_between {
    my ($percent, $min, $max, $array_ref) = @_;
    my $n = scalar @$array_ref;
    return 0 unless $n > 0;

    my @match = find_between( $min, $max, $array_ref );
    my $n_match = scalar @match;
    return ( ( $n_match / $n ) > ( $percent / 100 ) ) ? 1 : 0;
}

sub move_file {
    my ($file, $dest_dir) = @_;
    print "Moving $file to $dest_dir\n";
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
