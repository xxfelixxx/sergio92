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
# ok?
# bravo
# haha now I feel more stupid, ok lets contnnue :P
# FYI, there is no need to delete our conversation comments...
# when you 'git add -p' you can just say 'no' to adding those blocks...
# I see, ok lets conitunue


# here we are using debug jsut to debug :P
sub debug { }

# following steps are fine..
#Opening ligands.txt file
my $ligand_file = 'ligands.txt';
open( my $LIG, $ligand_file ) or die "Cannot open $ligand_file, $!";
debug("Reading ligands file: $ligand_file");
my %ligands_hash;
#Reading each line of the file
# ok, a little scoping lesson
# the variable $ligand, only exists here inside this for { ... } block
for my $ligand ( <$LIG> ) 
{
    # how I can comment this line (not chomp)
    # the line after?
    # yes

    chomp( $ligand ); # Remove trailing newline
    # Take note of when we have seen a particular ligand, for example 'HOH'
    # By setting $ligands_hash{ HOH } = 1
    # So later, we can get a list of which ligands we have seen by doing:
    # my @ligands_seen = keys %ligands_hash
    # Or checking if we have seen a particular ligand by checking for the
    # existance of a hash key, i.e. for ligand 'ABC':
    #  my $have_I_seen_abc = exists $ligands_hash{ABC}; # False
    # ok so if ligand appears then its 1 and we insert it into a hash
    #
    # Arrays can: push, pop, shift, unshift, length (scalar)
    # Hashes can: insert, delete, exists
    # ok so the main point here is that we have $ligands list..and we will match later
    # ligand_hash to the ligands from the other input files and look if they are matching
    # and if so we say 1?
    # Yes, the '1' has no meaning, we could set it to 'pony' or 'duck', it doesn't matter
    # ok i undestand..

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

            # here we are just giving values to these three variables?
            # what confuses me here a bit is that we had used $ligand to refer to
            # elements from ligand.txt file and now we are using it to refer to the
            # elements from the pdb file? $cols [3]
            # This $ligand variable only exists within the enclosing block, i.e.
            # between the if (.../^HEMATM/ ) { ... }
            # it is not related in any way to the $ligand variable we used before
            # we could give it (or the first one) a different name, to avoid confusion.
            # I see..i remember thing about scoping, i totally missed it here. Ok :)
            my ( $ligand, $chain_id, $res_no ) = ( $cols[3], $cols[4], $cols[5] );
            debug("--> Adding ligand $ligand to ligands_found hash");
            # Here we are jsut checking if ligand exists under this column (if its not empty)
            # and we are inserting these ligands into the ligand_found?
            # we are marking it as 'seen'
            # the '++' at the end means to auto-increment it
            # if we haven't seen it before, the key doesn't exist, but perl assumes
            # you want to increment it, so it defaults to 0, increment that and get 1
           $ligands_found{ $ligand }++;

            # If we ever are in the situation where $res_no is not defined, it means
            # that we didn't parse (split up) the line correctly, so we should bail out.
            # This is known in programming speak as an 'assertion'
            # I see, so here we were just checking if the values of these three variables exist?
            # yes, and the way perl works, the first one could exist, while the last one is
            # empty, say if the line was missing a column, so we check the last one, so we can
            # be assured that they all exist.
            # we could also do: defined $ligand and defined $chain_id and defined $res_no
            #                      or die ...
            # but this way is shorter
            # I see, it makes more sense because its last column
           defined $res_no
           or die "Unable to grok line: $line";

            # This works because perl automatically creates the missing
            # parts of nested hash (this is known as Autovivication).
            # The last part, the array is also created by the attempt
            # to push onto it, so perl assumes it should exist.
            #
            # This part when we use all this hashes is a bit confusing for me, let me guess
            #
            # This will create the following data structure:
            # Remind me what these things look like ligand = (HOH), chain (A..B..C) res_ID (123).
            # HOH -> A -> 123 -> [ line1, line2 ] # here
            #          -> 456 -> [ line3, line4 ]
            #     -> B -> 789 -> [ line5 ]
            # XYZ -> A -> 234 -> [ line8, line 9 ]
            #    ...
            # Ok, i understand..but since these are all one liners..it shouldnt look like this
            # #so basically it just linkes these lines and insert it into data_hash_ref?
            # yes, so each time inside this loop, it adds one more piece, and the data structure
            # gets bigger
            # I see, ok :)
            push @{ $data_hash_ref->{$ligand}->{$chain_id}->{$res_no} }, $line;
	    #push @{ $data_hash_ref->{$chain_id}->{$res_no} }, $line;
        }
    }

    debug("Processing ligands");
    # ok I am here.. Here we are just refering to ligands from t
    # So now we are just traversing the big data structure we just created above
    # Yes
    for my $ligand (sort keys %$data_hash_ref) 
    {
        # this number 1 was confusing mw a bit
        # it doesn't mean anything, I use that when I play with the debugger because
        # it gives me a distinct  line I can stop at, so I can tell the debugger, c 152
        1; # <- line 152
        # I see :P

        # Ok, so here we are checking if ligands are matching..but how ti interrpret this > 1:0
        # 1 = True, 0 = False
        # In perl, everything is true except for: 0, "0", (), and one more, I can't remember
        # ok ,  and this ? doesnt confuses perl that wee want to use some metacharacter or smth?
        #
        # ? is the ternary operator, if the thing to the left of the ? is true, it returns the
        # first thing, otherwise it returns the second thing (the thing after the colon :
        # I see..
        # $foo = is_bar ? 1 : 0;
        # is te same as writing:
        # if ( is_bar ) { $foo = 1; } else { $foo = 0 }
        # ok , i understand
        $is_in_ligands_txt = defined $ligands_hash{$ligand} ? 1 : 0;
        debug("--> Ligand $ligand, is_in_ligands_txt = $is_in_ligands_txt");


        # here its also the same just we are refering to chain_id that is just after ligand?
        # yeah, so it refers to the inner bits of the datastructure we created before
        for my $chain_id ( keys %{ $data_hash_ref->{$ligand} } )
	{
            for my $res_no ( keys %{ $data_hash_ref->{$ligand}->{$chain_id} } )
	    {
                debug("------> Chain Id = $chain_id, Res No = $res_no");
                my @lines = @{ $data_hash_ref->{$ligand}->{$chain_id}->{$res_no} };

                # Here we are just checking conditions if ligand is found under ligands.txt
                # and if the size of lines are more then 1? W...hyy udo we checkign that?
                # Because that is what you wanted....yes of course, but does it prints
                # only those lines taht are identical to each other?
                # #Just the lines we stored above..yeah but if they are identical then its >1?
                # If it shows up more than once, then yes..they have to be identical in each
                # hash key and value?  We can check if lines are duplicated...that is why
                # we uniq ...but we could check that first, i.e. uniq the @lines and then
                # check that there are more than 1. So this part is actually just checking
                # if there are some lines that are not unique..sorted..that are duplicated
                # no, it just checks that there are some lines...it doesn't evaluate them
                # now I undestand..sorry :P
                if ( $is_in_ligands_txt and scalar @lines > 1 )
		{

                    # Output filename based on first ligand with $chain_id and $res_no combo
                    # Are these steps when we are saying that if after ligand chain_id or res_id
                    # seems t be identical then print it into same file output.
                    # No, just print everything...but when we actually print, we remove duplicates
                    # You may wish to move the uniq logic to before this block

                    # Unique I understand..but if u remember if ligand is HOH and chain ID is A
                    # and B with the same or similar res_id we wanted it all to be unique..and
                    # in one file we will have HOH A 147 (multiple lines) other file
                    # HOH B 142 (147)..do u remember these steps? yes/no/maybe
                    # so....this....this is why you _want_ tests for your code
                    # so you can say that with input X, Y, Z, you get ABC
                    # because it is very difficult to remember all of the logic you need/want
                    # but if you have test files, and expected results, then you can just
                    # keep modifying your code until you pass the tests, then you are done.
                    # The script is working good just cant find where we said that if chain_id
                    # or res_id values appear more then once and ligand doesn't change
                    # not sure....would be useful to have a test file to demonstrate what you mean
                    # ok jsut give me a sec..
                    # u saw the output..u can see that in these cases ligand name was the same
                    # while chain and res_id were different between two or more files that have
                    # same ligand, right?
                    # I was struggling to find where we assigned this in the script..
                    #
                    my $outfile = join( '#', $ligand, $chain_id, $res_no ) . '.txt';
                    my $nl = (scalar @lines);

                    #This part..
                    # I am just being pedantic (picky)
                    # Appending 1 line vs Appending 2 lines...notice the 's'..yes..
                    # Ok i understand it now :)
                    # Changes made to this file are now saved and can be moved to github?
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

