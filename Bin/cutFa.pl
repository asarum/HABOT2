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

die "perl $0 <ref.fasta> <out.fasta> <len:20000> <ovl:1000>\n" if(@ARGV==0);

my($infile, $outfile, $max_len, $ovl) = @ARGV;

my($id, $seq);
$max_len ||= 20000;
$ovl ||= 1000;

my $in_hdl = myOpen($infile);
my $ou_hdl = myOpen(">$outfile");
while (getSeq($in_hdl,\$id,\$seq)!=-1)
{
	my $len = length($seq);
	for(my $i=0; $i<$len; $i+=$max_len-$ovl)
	{
		my $sub_seq = substr($seq,$i,$max_len);

		my $new_id = "${id}:$i";
		print $ou_hdl ">$new_id\n";
        formatSeq($sub_seq);
	}
}
close $in_hdl;
close $ou_hdl;

sub formatSeq{
    my $seq = shift;
    my $len = length($seq);
    my $sub_len = 80;
    for(my $i=0; $i<$len; $i+=$sub_len)
    {
        my $sub_seq = substr($seq, $i, $sub_len);
        print $ou_hdl "$sub_seq\n";
    }
}
