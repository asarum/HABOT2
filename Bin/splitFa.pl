#!/usr/bin/perl
use warnings;
use strict;
use FindBin qw($Bin);
use Getopt::Long;
use File::Basename;
use Cwd qw(abs_path getcwd);

BEGIN {
    push (@INC,"$Bin");
}
use SeqIO;

die "perl $0 <ref.fasta> <outdir> <prefix> <base:20000000> <num:50>\n" if(@ARGV==0);

my($infile, $outdir, $prefix, $max_base, $max_num) = @ARGV;
$infile = abs_path($infile);
$max_base ||= 20000000; # 20M
$max_num ||= 50;

mkdir($outdir) if(!-e $outdir);
chdir $outdir;

my $index = 0;
my $base  = 0;

my($id, $seq);
my $outfile = "$prefix.tmp";
my $in_hdl = myOpen($infile);
my $ou_hdl = myOpen(">$outfile");
while (getSeq($in_hdl,\$id,\$seq)!=-1)
{
    print $ou_hdl ">$id\n$seq\n";
	my $len = length($seq);
	$base += $len;
    output() if($base >= $max_base);
}
output();
close $in_hdl;
close $ou_hdl;

`rm $outfile`;

sub output{
    return if($base==0);
    my $dir_idx = int($index/$max_num);
    my $out_dir = "Split_$dir_idx";
    mkdir($out_dir) if(!-e $out_dir);
    close $ou_hdl;
    `mv $outfile $out_dir/$prefix.$index.fasta`;
    # reset
    $index++;
    $base = 0;
    $ou_hdl = myOpen(">$outfile");
}
