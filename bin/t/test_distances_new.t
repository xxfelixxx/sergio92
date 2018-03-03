#!/usr/bin/env perl

use warnings;
use strict;

use Time::HiRes qw( gettimeofday tv_interval );
use Test::More;
use FindBin qw($Bin);
use File::Path qw( make_path remove_tree );
use File::Copy;

# Test script for Distance.pl
# Run as: prove -v test_distances_new.t
#  --or--     perl test_distances_new.t

chomp(my $sha1sum = `which sha1sum`);

my $creating_ligand_files_script = 'creating_ligand_files.pl';
my $distances_script = 'distances_new.pl';
my $test_data = 'test_ligand_data';
my $expected = 'expected_atom_coordinates';

my $test_path = "$Bin/.test_" . $distances_script . '_' . time() . '_' . $$; # $$ is process_id
note("Creating testing directory $test_path");
make_path( $test_path )
    or die "Unable to create $test_path : $!";

for my $script_name ( $creating_ligand_files_script, $distances_script ) {
    my $script = "$Bin/../" . $script_name;
    ok( -f $script, "Found $script_name script" )
        or BAIL_OUT( "$script not found!" );
    note("Copying $script to $test_path");
    copy( $script, $test_path );
}

note("Copying test files from $test_data to $test_path");
my @test_files = (
    # TODO: better data to test with...
    { name => '1A2C.pdb',    sha1 => '7831b86a55daf0db4c95739532b3cea2e727a0c9' },
    { name => 'ligands.txt', sha1 => '185f5c93bf46c2d94d226cea612292cf8cfa3b81' },
);
for my $file_data ( @test_files ) {
    my $file = $file_data->{name};
    my $src = "$Bin/$test_data/$file";
    note("Copying $file to $test_path");
    copy( "$src", $test_path )
        or die "Unable to copy $src to $test_path";
    note("TODO: Validate sha1");
}

pass("We have the test files and scripts all in $test_path.");

# $^X is a perl variable for the path of 'perl', see: perldoc perlvar
my $create_cmd = "cd $test_path && $^X $creating_ligand_files_script";
note("Executing the creating_ligand_files_script on the test directory");
(system($create_cmd) == 0)
    or BAIL_OUT("Unable to run '$create_cmd' : $!");
pass("Script 1 ran ok");

my $ligands_txt = $test_path . '/ligands.txt';
if ( -f $ligands_txt ) {
    note("Removing ligands.txt");
    unlink $ligands_txt
        or die "Unable to unlink $ligands_txt : $!";
} 


chomp(my @txt_files = `ls $test_path | grep '.txt'`);
note("Found " . scalar @txt_files . " ligands: " . join(' ', map { s/\#.*$//; $_ } @txt_files ));
my $percent = 70;
my $distance_cmd = "cd $test_path && $^X $distances_script --percent=$percent";
note("Executing distances.pl with percent = $percent");
note("[ $distance_cmd ]");
my $t0 = [gettimeofday];
(system($distance_cmd) == 0)
    or BAIL_OUT("Unable to run '$distance_cmd' : $!");
my $elapsed = tv_interval ( $t0, [gettimeofday]);
pass("Script 2 ran ok - took $elapsed seconds");

my %expected_files = (
    'covalently_bound' => [ '34H#J#1.txt', 'PRJ#J#3.txt'],
    '2_4'              => [ 'OAR#J#4.txt' ]
);

# Now we check the results
for my $result_dir ( sort keys %expected_files ) {
    my $result_path = "$test_path/$result_dir";
    opendir my $dir, $result_path
    or die "Unable to opendir $result_path : $!";
    my @found_files = grep { !/~$/ && ! /^\./ && -f "$result_path/$_" } readdir($dir);
    my $nfound = scalar @found_files;
    my @expected_files = @{ $expected_files{$result_dir} };
    my $nexpected = scalar @expected_files;
    note("Checking files found in $result_dir directory");
    ok($nfound == $nexpected, "Correct number [ $nexpected ] : " . join(' ', @expected_files))
        or diag("Expected $nexpected but got $nfound files!\n"
                . join(' ', @found_files) . "\nvs\n" . join(' ', @expected_files));
}

my $builder = Test::More->builder();
if ( $builder->is_passing() ) {
    note("Cleaning up $test_path");
    remove_tree( $test_path );
} else {
    note("NOT CLEANING UP [ $test_path ]");
}

done_testing();

sub sha1 {
    my ($file) = @_;
    # TODO: There is a proper perl library to do this...
    chomp(my $sha1 = qx( $sha1sum $file | cut -b-40 )); # 40-characters
    return $sha1;
}

sub show_diff {
    my ($f1, $f2) = @_;
    my $diff = '/usr/bin/diff';
    if ( -f $diff ) {
        my $cmd = "$diff $f1 $f2";
        system($cmd);
    } else {
        note("NEED TO FIX DIFF PATH!");
    }
}
