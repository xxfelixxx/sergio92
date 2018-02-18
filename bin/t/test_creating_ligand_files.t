#!/usr/bin/env perl

use Test::More;
use FindBin qw($Bin);
use File::Path qw( make_path remove_tree );
use File::Copy;

# Test script for Creating Ligand Files script
# Run as: prove -v test_creating_ligand_files.t
#  --or--     perl test_creating_ligand_files.t

chomp(my $sha1sum = `which sha1sum`);

my $script_name = 'creating_ligand_files.pl';
my $test_data = 'test_ligand_data';
my $expected = 'expected_atom_coordinates';

my $script = "$Bin/../$script_name";
ok( -f $script, "Found $script_name script" )
    or diag( "$script not found!" );

my $test_path = "$Bin/.test_$script_name" . '_' . time() . '_' . $$; # $$ is process_id
note("Creating testing directory $test_path");
make_path( $test_path )
    or die "Unable to create $test_path : $!";

note("Copying $script to $test_path");
copy( $script, $test_path );

note("Copying test files from $test_data to $test_path");
my @test_files = (
    { name => '1A5Z.pdb',    sha1 => '2265983f407748b6a7c44ad6bfd4d65efcc2f307' },
    { name => '1A7L.pdb',    sha1 => '1f6433139291b27614d1fe2744df067c427f86bb' },
    { name => 'ligands.txt', sha1 => '185f5c93bf46c2d94d226cea612292cf8cfa3b81' },
);
for my $file_data ( @test_files ) {
    my $file = $file_data->{name};
    note("Copying $file to $test_path");
    copy( "$test_data/$file", $test_path )
        or die "Unable to copy $test_data/$file to $test_path";
    note("TODO: Validate sha1");
}

pass("We have the test files and scripts all in $test_path.");


# $^X is a perl variable for the path of 'perl', see: perldoc perlvar
my $cmd = "cd $test_path && $^X $script_name";
note("Executing the script on the test directory");
(system($cmd) == 0)
    or BAIL_OUT("Unable to run '$cmd' : $!");
pass("Script ran ok");

# Now we check the results

opendir my $dir, $expected
    or die "Unable to opendir $expected : $!";

# Ignore any possible dot files, or ~ backup files
my @expected_files = grep { !/~$/ && ! /^\./ && -f "$expected/$_" } readdir($dir);
for my $file (@expected_files) {
    my $sha1 = sha1("$expected/$file");
    my $tfile = "$test_path/$file";
    ok( -f $tfile, "Found $tfile" );
    my $tfile_sha1 = sha1($tfile);
    ok($sha1 == $tfile_sha1, "$file has correct checksum")
        or show_diff( "$expected/$file", $tfile );
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
