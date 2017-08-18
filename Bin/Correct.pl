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

    Correct.pl  --Correct genome.fa with other.fa

=head1 Usage

    perl Correct.pl [arguments] <genome.fa> <other.fa>

    Argument List:
                  -c <INT>        the software to do correction[1]
                                  1. PBDAGCON
                                  2. PROREAD, only suitable for illumina contig

                  -g <FILE>       the unique kmer(.h5 or .bit)
                  -k <INT>        the kmer size of the unique graph[17]
                  -u <INT>        the min unique kmer[3]

                  -s <INT>        split the reference file, in unit of M[100].
                  -s2<INT>        split the query file, in unit of M[-1,all_data].

                  -x <INT>        the scope to align[-1]
                  -j <INT>        the jump length to get kmer[1]
                  -n <INT>        max align number for query [2]

                  -t <INT>        thread number[4]
                  -m <INT>        align mode[1]
                                  1. align with LCS,for uncrrected reads
                                  2. align with kmer, for corrected reads

                  -d <DIR>        the output directory [Consensus]

                  -b <STR>        the pro_name [pb_cor]
                  -q <STR>        the queue of sge [dna.q,rna.q,reseq.q]
                  -p <STR>        the project of sge [og]


=head1 Example

perl Correct.pl -g k17.bit -k 17 -u 3 -n 10 ref.fa query.fa

=cut

my(
$opt_g, $opt_k, $opt_u,   # kmer
$opt_s, $opt_s2,          # split size
$opt_j, $opt_n, $opt_x,   # scope
$opt_t, $opt_m,           # speed
$opt_c, $opt_d,           # output
$opt_b, $opt_q, $opt_p,   # qsub
$help
);

# Get parameters
# ==============================================================================
# |
GetOptions(
"g:s"     => \$opt_g,
"k:i"     => \$opt_k,
"u:i"     => \$opt_u,

"s:i"     => \$opt_s,
"s2:i"    => \$opt_s2,

"x:i"     => \$opt_x,
"j:i"     => \$opt_j,
"n:i"     => \$opt_n,

"t:i"     => \$opt_t,
"m:i"     => \$opt_m,

"c:i"     => \$opt_c,
"d:s"     => \$opt_d,

"b:s"     => \$opt_b,
"q:s"     => \$opt_q,
"p:s"     => \$opt_p,

"help|h"  => \$help,
);

my($ref, $query) = @ARGV;

checkParam();

$opt_g ||= -1;
$opt_k ||= 17;

$opt_g = abs_path($opt_g);
$opt_u ||= 3;
$opt_x ||= -1;

$opt_s ||= 100;
$opt_s2 ||= -1;

$opt_j ||= 1;
$opt_n ||= 2;
$opt_t ||= 4;
$opt_m ||= 1;

$opt_c ||= 1;
$opt_d ||= "Consensus";

$opt_b ||= "pb_cor";
$opt_q ||= "dna.q,rna.q,reseq.q";
$opt_p ||= "og";

$ref   = abs_path($ref);
$query = abs_path($query);
$opt_d = abs_path($opt_d);
# |
# ==============================================================================


# Software path
# ==============================================================================
# |
my $CUTFA = "perl $Bin/cutFa.pl";
my $ALIGN = "perl $Bin/Align.pl";

my $CONVERT = "perl $Bin/al2bb.pl";
my $PBSPLIT = "perl $Bin/pbsplit.pl";

my $PBDAGCON  = "perl $Bin/pbdagcon.pl";
my $PROOVREAD = "perl $Bin/proovread.pl";
# |
# ==============================================================================


# Direcotory
# ==============================================================================
#
my $dir_data  = "$opt_d/Data";
my $dir_align = "$opt_d/Align";
my $dir_corr  = "$opt_d/Result";

mkdir "$opt_d";
mkdir "$dir_data";
mkdir "$dir_corr";

chdir ($opt_d);
my $pwd = getcwd();
# |
# ==============================================================================

# Cut other.fa with length of 20k
# ==============================================================================
#
my $cmd = "$CUTFA $query $dir_data/other.fa";
system($cmd);
$query = "$dir_data/other.fa";
# |
# ==============================================================================



# Do alignment
# ==============================================================================
#
$cmd = "$ALIGN -g $opt_g -k $opt_k -u $opt_u -s $opt_s -s2 $opt_s2 ";
$cmd .= "-x $opt_x -j $opt_j -n $opt_n -t $opt_t -m $opt_m -d $dir_align ";
$cmd .= "-b $opt_b -p $opt_p -q $opt_q ";
$cmd .= "$ref $query";
debug($cmd);
system($cmd);
# |
# ==============================================================================



# Split sequences into small files
# ==============================================================================
#
chdir($dir_corr);

$cmd  = "cd $dir_corr && ";
$cmd .= "$CONVERT  $dir_align/align.al backbone.lst && ";
$cmd .= "$PBSPLIT -a $ref -b $query -l backbone.lst -d Split";

my $cmd_file = "PREPARE.sh";
outShell2("prepare.sh\t$cmd", $cmd_file);

qsub($cmd_file, "$dir_corr/Shell", "5G", 1,
            $opt_q, $opt_p, $opt_b, 50);
#
# ==============================================================================



# Do consensus
# ==============================================================================
#
chdir("$dir_corr/Shell");

my $list = `ls $dir_corr/Split/*/*.subreads.fasta`;
my @files = split(/\n/, $list);
my @shell_cors;

# generate correct shells #
$cmd = "";
my $index = 0;
foreach my $read (@files)
{
    my $sub_ref = $read;
    $sub_ref =~ s/\.subreads//;

    my $dir = dirname($read);
    $cmd .= "cd $dir\n";
    $cmd .= "$PBDAGCON  $sub_ref $read $opt_t 1\n" if($opt_c==1);
    $cmd .= "$PROOVREAD $sub_ref $read $opt_t\n" if($opt_c==2);

    $index++;
    outCor()  if($index%20==0);
}
outCor();

# generate config file #
open FO, ">Correct.cfg" or die $!;
foreach my $shell(@shell_cors){
    print FO "$shell:5G\n";
}
close FO;

# qsub jobs
qsub2("Correct.cfg", $opt_t, $opt_q, $opt_p, $opt_b, 50);

# cat files
$cmd  = "cd $dir_corr\n";
$cmd .= "cat $dir_corr/Split/*/*.consensus > correct.fa && ";
$cmd .= "rm -r $dir_data && ";
$cmd .= "rm -r $dir_corr/Split";
system($cmd);

sub outCor
{
    return if($cmd eq "");
    my $index2 = int($index/20);
    my $shell = abs_path("pbdagcon_$index2.sh");

    $cmd .= "echo done";
    outShell2($cmd, $shell);
    push(@shell_cors, $shell);

    $cmd = "";
}
#|
#
# ==============================================================================



# check parameters
# ==============================================================================
#
sub checkParam
{
	if ($help || @ARGV != 2) {
        die `pod2text $0`;
    }
}
#
# ==============================================================================
