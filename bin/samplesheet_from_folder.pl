#!/usr/bin/env perl

use strict;
use Getopt::Long;
use Cwd 'abs_path';

my $usage = qq{
perl my_script.pl
  Getting help:
    [--help]

};

my $folder = undef;
my $help;

GetOptions(
    "folder=s" => \$folder,
    "help" => \$help );

# Print Help and exit
if ($help) {
    print $usage;
    exit(0);
}

my @files = glob( $folder . '/*.fastq.gz' );

my %groups;
my %samples;
foreach my $file (@files) {
	my $fpath = abs_path($file);
	my $group = (split /_R[0-9]/, $file)[0];
	if (defined $groups{$group}) {
		push( @{ $groups{$group} },$fpath);
	} else {
		$groups{$group} = [ $fpath ];
	}
}

printf "patientID,sampleID,libraryID,rgID,R1,R2\n";

foreach my $group (keys %groups) {

	# 220400005493-DS9_22Apr5493-DL009_S9_L002_R1_001.fastq.gz

	my @reads = @{ $groups{$group} };
	my $left = @reads[0];
	my $right = @reads[1];

	my $base_name = (split "/", $left)[-1];
	#my $sample = (split /_S[0-9]*_/, $base_name)[0] ;
	#my $library = (split /_L0[0-4]_/, $sample)[0] ;
	my $sample = (split /_/, $base_name)[1] ;

	chomp($sample);

	printf STDERR $sample . "\n";

	my $header = `zcat $left | head -n1`;

	my $info = (split " ",$header)[0] ;
	my ($instrument,$run_id,$flowcell_id,$lane,$tile,$x,$y) = (split ":", $info);
	my $readgroup = $flowcell_id . "." . $lane . "." . $sample ;
	chomp($readgroup);	
	printf $sample . "," . $sample . "," . $library . "," . $readgroup . "," . $left . "," . $right . "\n";

}

