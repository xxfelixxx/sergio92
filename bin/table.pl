#!/usr/bin/env perl

use strict;
use warnings;
use diagnostics;

#my $testfile=shift;
open(INPUT, "$ARGV[0]") or die 'Cannot make it';
my @file=<INPUT>;
close INPUT;
my @ac;
my @dr;
my @os;
my @or;
my @fo;

for (my $line=0;$line<=$#file;$line++)   
{
chomp($file[$line]);
        if ($file[$line] =~ /^HEADER/)   
	{
		print( (split '\s+', $file[$line])[-1]);
		print "\t";
		
		while ($file[$line] !~ /^END /)        
                {
                $line++;
			 if ($file[$line]=~/^EXPDTA/)
        		 {
				$file[$line]=~s/^EXPDTA//;
                		@os = (@os,split '\s+', $file[$line]);
				print "$os[1] $os[2]\t";
				print "\t";
				@os=();
        		 }
                        	if ($file[$line] =~ /^REMARK   2 RESOLUTION./) 
                        	{
                        		$file[$line]=~s/^REMARK   2 RESOLUTION.//;
                       			@ac = (@ac,split'\s+',$file[$line]);
					print "$ac[3] $ac[4]\t" or die "Cannot be printed";
					print "\t";
					@ac=(); 
                        	}
					if ($file[$line] =~ /^HETNAM/)
					{
						$file[$line]=~s/^HETNAM//;
						$file[$line] =~ s/\s+//;
						push @dr, $file[$line];
					}
						if ($file[$line] =~ /^SOURCE   2 ORGANISM_SCIENTIFIC/) 
                       				{
                       					$file[$line]=~s/^SOURCE   2 ORGANISM_SCIENTIFIC//;
                        				@or = (@or,split'\s+',$file[$line]); 
							print "$or[2] $or[3]\t" or die "Cannot be printed";
							print "\t";		
							@or=();
                        			}
							if ($file[$line] =~ /^FORMUL/)
							{
								$file[$line]=~s/^FORMUL//;
								$file[$line] =~ s/\s+//;
								push @fo, $file[$line];
							}
                }
		foreach (@dr)
		{
			print "$_";
			print "\t\t\t\t\t";
		}
		@dr=();
		print "\n";

		foreach (@fo)
		{
			print "$_";
			print "\t\t\t\t\t";
		}
		@fo=();
		print "\n";
	}
}

