#!/usr/bin/env perl

use warnings;
use strict;

use Test::More;
use FindBin qw($Bin);

my $script = "$Bin/../excluding_ions_solvents.pl";
ok( -f $script, "Found excluding_ions_solvents.pl script" );

my @test_files = (
    {
        name => '1A0T.pdb', 
        sha1 => '4062108f5d95f76a8fdcb6eb2f6d155e6473104b',
        lig  => 'SUC',
    },
    {
        name => '1A2C.pdb',
        sha1 => '7831b86a55daf0db4c95739532b3cea2e727a0c9',
        lig  => '34H_OAR_PRJ_TYS',
    },
);

for my $file_data ( @test_files ) {
    my $file = join('/', 'test_ligand_data', $file_data->{name});
    ok( -f $file, "Found " . $file_data->{name} );
    my $expected = join('_', $file_data->{name}, $file_data->{lig} );
    chomp(my $result = qx( $script $file ));
    ok( $result =~ m|$expected$|, "Found correct ligands: " . $file_data->{lig} )
        or diag("Got $result, Expected $expected");
}

done_testing();
