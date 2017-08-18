use strict;
use warnings;
use FindBin qw($Bin);
use Getopt::Long;
use File::Basename;
use Cwd qw(abs_path getcwd);

BEGIN {
    push (@INC,"$Bin");
}
use SeqIO;
use Qsub;


# Get parameters
# ==============================================================================
# |
die "perl $0 <input.cfg>\n" if(@ARGV==0);
my($cfg_file) = @ARGV;

# reference 
my $ref;

# pb file
my($genome_size, $pb_lst, $filt_len);

# data type
my $is_correct = 0;

# kmer
my($kmer_file, $kmer_size);

# align strategys
my($k_size, $min_ovl, $mode, $score);

# sge 
my($queue, $project, $pro_name, $job_num);

parseCfg($cfg_file);
# |
# ==============================================================================


# Global Variables
# ==============================================================================
# |
my $SLEEP = 300;
# |
# ==============================================================================


# Software Paths
# ==============================================================================
# |
my $MERGEFILE = "perl $Bin/mergeFiles.pl";
my $CONTIG = "perl $Bin/get_scaftig.pl";
my $ALIGN = "perl $Bin/Align.pl";

my $FILTER  = "perl $Bin/filtAl_c.pl";
my $CONVE = "perl $Bin/convert_c.pl";
my $LINK = "perl $Bin/link_c.pl";

my $CORRECT = "perl $Bin/Correct.pl";
# |
# ==============================================================================



# 目录结构
# ==============================================================================
# |
mkdir ("Data");
mkdir ("Shell");
mkdir ("CloseGap");
mkdir ("Consensus");

my $dir_shell = abs_path("Shell");
my $dir_align = abs_path("Align");
my $dir_close = abs_path("CloseGap");
my $dir_correct = abs_path("Consensus");
# |
# ==============================================================================



# 对数据进行过滤和重命名
# ==============================================================================
# |

# 准备原始数据
debug("merge pacbio files...");

my $pb_data = abs_path("Data/pb.fasta");
my $contig = abs_path("Data/contig.fasta");

my $cmd = "$MERGEFILE $pb_lst $filt_len $pb_data\n";
$cmd .= "$CONTIG $ref > $contig\n";

system($cmd);
# |
# ==============================================================================


# 比对
# ==============================================================================
# |
debug("do alignment...");

$cmd  = "$ALIGN -k $k_size ";
$cmd .= "-g $kmer_file -u 3 " if($kmer_size == $k_size);
$cmd .= "-s 400 -n 2 -x $min_ovl -m $mode -t 8 ";
$cmd .= "-q $queue -p $project -b $pro_name ";
$cmd .= "-d $dir_align $contig $pb_data\n";

system($cmd);
# |
# ==============================================================================


# 聚类与连接
# ==============================================================================
# |
debug("closing gap...");

# 转换格式
$cmd = "cd $dir_close && ";
$cmd .= "$FILTER $dir_align/align.al filter.al 100 $score && ";
$cmd .= "$CONVE filter.al convert.al && ";

# 连接
my $simi = 0.001;
$simi = 0.1 if($is_correct==1);
$cmd .= "$LINK $contig $pb_data convert.al.best closeGap.fa $simi";

# 提交任务
my $cmd_file = "$dir_shell/CLOSEGAP.SH";
outShell2("closegap.sh\t$cmd", $cmd_file);

qsub($cmd_file, "$dir_shell", "5G", 1,
                $queue, $project, $pro_name, 50);
# |
# ==============================================================================



# 纠错
# ==============================================================================
# |
debug("correct files...");

my $input = "$dir_close/closeGap.fa";
$cmd  = "cd $dir_correct\n";
$cmd .= "$CORRECT -k $k_size -u 3 ";
$cmd .= "-g $kmer_file -u 3 " if($kmer_size==$k_size);
$cmd .= "-s 400 -n 2 -t 8 ";
$cmd .= "-j 10 -m 2 " if($is_correct==1);
$cmd .= "-j 1  -m 1 " if($is_correct==0);
$cmd .= "-b $pro_name -q $queue -p $project ";
$cmd .= "-d $dir_correct $input $pb_data ";

system($cmd) if($is_correct==0);
# |
# ==============================================================================



# 从配置参数中取得参数
# ==============================================================================
# |
sub parseCfg{
    my $cfg_file = shift;
    my $cfg_hdl = myOpen($cfg_file);

    while (<$cfg_hdl>) {
        chomp;
        next if(/^#/);
        next if(!/^\[/);
        my($key, @values) = split;

        # contig
        $ref = $values[0] if($key eq "[reference]");

        # pb file
        $pb_lst = $values[0] if($key eq "[pb_lst]");
        $filt_len = $values[0] if($key eq "[filt_len]");
        $genome_size = $values[0] if($key eq "[genome_size]");

        # is correct 
        $is_correct = $values[0] if($key eq "[is_correct]");

        # kmer
        ($kmer_file,$kmer_size) = @values if($key eq "[unique_kmer]");

        # qsub job
        $queue = $values[0] if($key eq "[queue]");
        $project = $values[0] if($key eq "[Project]");
        $pro_name = $values[0] if($key eq "[pro_name]");
        $job_num = $values[0] if($key eq "[max_job]");

        # strategy
        ($k_size, $min_ovl, $mode, $score) = @values if($key eq "[strategy]");

    }
    $ref = abs_path($ref);
    $genome_size *= 10**6;
    $kmer_file = abs_path($kmer_file);
    $pb_lst = abs_path($pb_lst);
    close $cfg_hdl;
}
# |
# ==============================================================================


