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
use Qsub;
use SeqIO; 

=head1 Name

    KmerBatch.pl  --Generate kmer bits and get the different between them.

=head1 Usage

    perl KmerBatch.pl [arguments] <sample.info>

    Argument List:
                  -k <INT>        the kmer size[16]
                  -m <INT>        the min occ of kmer[3]

                  -s <INT>        the output kmer type[5]
                                  3: output unique k-mers
                                  5: output all k-mers

                  -d <DIR>        the output directory [KmerBatch]

                  -b <STR>        the pro_name [parseBit]
                  -q <STR>        the queue of sge [dna.q,rna.q,reseq.q]
                  -p <STR>        the project of sge [og]

    <sample.info>:

        sample1 read1
        sample1 read2
        sample2 read3
        sample3 read4

=head1 Example

perl KmerBatch.pl sample.info

=cut

my(
$opt_k, $opt_m,   		# kmer
$opt_s, $opt_d,         # output
$opt_b, $opt_q, $opt_p, # qsub
$help
);

# Get parameters
# ==============================================================================
# |
GetOptions(
"k:i"     => \$opt_k,
"m:i"     => \$opt_m,
"s:i"     => \$opt_s,

"d:s"     => \$opt_d,

"b:s"     => \$opt_b,
"q:s"     => \$opt_q,
"p:s"     => \$opt_p,

"help|h"  => \$help,
);

my($sample_lst) = @ARGV;

checkParam();

$opt_k ||= 16;
$opt_m ||= 3;
$opt_s ||= 5;

$opt_d ||= "KmerBatch";
$opt_d = abs_path($opt_d);

$opt_b ||= "parseBit";
$opt_q ||= "dna.q,rna.q,reseq.q";
$opt_p ||= "og";
# |
# ==============================================================================



# Software path && Directory
# ==============================================================================
# |
my $GRAPH = abs_path("$Bin/Graph.pl");
my $STAT  = "$Bin/getKmer";

my $dir_shl = "$opt_d/Shell";
`mkdir -p $dir_shl`;
# |
# ==============================================================================


# Load Sample File
# ==============================================================================
# |
my %sample_hash;
my $lst_hdl = myOpen($sample_lst);
while (<$lst_hdl>) {
	chomp;
	my($id, $file) = (split)[0,1];
	die "don't exists $file\n" if(!-e $file);
	
	$file = abs_path($file);
	$sample_hash{$id} .= "$file\n";
}
close $lst_hdl;
# |
# ==============================================================================



# Generate Kmer Bits
# ==============================================================================
# |
my $cfg_info;
while (my($sample, $files) = each %sample_hash) 
{
	my $dir = "$opt_d/$sample";
	system("mkdir -p $dir");

	# file list
	outShell2("$files", "$dir/file.lst");
	
	# command
	my $cmd = "cd $dir && "; 
	$cmd .= "perl $GRAPH pipe  ";
	$cmd .= "-i file.lst ";
	$cmd .= "-m $opt_m ";
	$cmd .= "-k $opt_k ";
	$cmd .= "-s 1,$opt_s ";
	$cmd .= "-d $dir ";
	
	# script
	my $script = "kmer_$sample.sh";
	
	# config file
	$cfg_info .= "$script $cmd\n";
}
outShell2($cfg_info, "$dir_shl/GRAPH.cfg");
qsub("$dir_shl/GRAPH.cfg", $dir_shl, "10G", 4,
                                $opt_q, $opt_p, $opt_b, 50);
# |
# ==============================================================================



# get stats for bits
# ==============================================================================
# |
$cfg_info = "";
foreach my $sample(keys %sample_hash) 
{
	my $dir = "$opt_d/$sample";
	
	# other bit list
	my $other_info;
	my $sub = "03.All_bit";
	$sub = "02.Uinque_bit" if($opt_s==3);

	foreach my $other(keys %sample_hash)
	{
		next if($other eq $sample);
		$other_info .= "$opt_d/$other/$sub/kmer_${opt_k}.bit\n";
	}
	outShell2($other_info, "$dir/other.lst");
	# generate script
	my $script = "stat_$sample.sh";
	my $cmd = "cd $dir && ";
	$cmd .= "$STAT -i $dir/$sub/kmer_${opt_k}.bit -f other.lst -o stat.log";
	$cfg_info .= "$script $cmd\n";
}
# die "$cfg_info\n";
outShell2($cfg_info, "$dir_shl/STAT.cfg");
qsub("$dir_shl/STAT.cfg", $dir_shl, "5G", 4,
                                $opt_q, $opt_p, $opt_b, 50);
# |
# ==============================================================================



# check parameters
# ==============================================================================
#
sub checkParam
{
	if ($help || @ARGV != 1) {
        die `pod2text $0`;
    }
}
#
# ==============================================================================
