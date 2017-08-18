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

# pb file
my($genome_size, $pb_lst, $filt_len);

# 1: uncorrected
# 2: corrected
my $data_type;

# kmer
my($kmer_file, $kmer_size);

# sge
my($queue, $project, $pro_name, $job_num);

# assembly strategys
my @strategys;

# thread
my $thread = 8;

parseCfg($cfg_file);
# |
# ==============================================================================


# Software Paths
# ==============================================================================
# |
# prepare data
my $MERGE = "perl $Bin/mergeFA.pl";

# link
my $ALIGN = "perl $Bin/Align.pl";
my $FILTER  = "perl $Bin/filtAl.pl";
my $GRAPH   = "perl $Bin/buildGraph.pl";
my $LINK    = "perl $Bin/link.pl";

# compress
my $CMPR  = "perl  $Bin/Compress.pl";
my $SORT_FILE = "perl $Bin/sortSeq.pl";
# |
# ==============================================================================


# 对数据进行过滤和重命名
# ==============================================================================
# |
mkdir ("Data");
mkdir ("Shell");

my $pb_data = abs_path("Data/data.fasta");

# 重命名
my $cmd = "$MERGE $pb_lst $filt_len $pb_data \n";
system($cmd);
# |
# ==============================================================================


# 核心组装过程
# ==============================================================================
# |
my $index = 0;
foreach(@strategys)
{
    debug($_);

    # 比对参数设置
    # ==========================================================================
    # |
    my($k_size, $min_ovl, $mode, $score, $min_len, $jump) = split;
    $min_len ||= 500;
    $jump ||= 10;
    $jump = 10 if($jump==1 && $mode==2);
    # |
    # ==========================================================================


    # 目录结构
    # ==========================================================================
    # |
    $index++;
    mkdir "Process_$index";
    chdir "Process_$index";

    mkdir("Align");
    mkdir("Assembly");

    my $dir_align = abs_path("Align");
    my $dir_assem = abs_path("Assembly");
    # |
    # ==========================================================================


    # 对序列进行比对
    # ==========================================================================
    # |
    my $divide_size = int($genome_size/10**6)+1;
    $divide_size=400 if($divide_size>400);

    my $max_num = 10;
    $max_num = 3 if($index>1);

    $cmd  = "$ALIGN -k $k_size  -s $divide_size ";
    $cmd .= "-g $kmer_file -u 1 " if($k_size==$kmer_size);
    $cmd .= "-j $jump ";
    $cmd .= "-t $thread ";
    $cmd .= "-n $max_num ";
    $cmd .= "-s2 -1 -x $min_ovl -m $mode -d $dir_align $pb_data $pb_data\n";

    system($cmd);
    # |
    # ==========================================================================


    # 数据聚类
    # ==========================================================================
    # |
    my $simi = 0.5;
    $simi = 0 if($data_type==1);

    $cmd  = "cd $dir_assem && ";
    $cmd .= "$FILTER $dir_align/align.al filter.al $min_len $score && ";
    $cmd .= "$GRAPH filter.al graph.info && ";
    $cmd .= "$LINK $pb_data short.lst graph.info assemble.fasta $simi ";
    $cmd .= " && echo done\n";

    my $cmd_file = "$dir_assem/DENOVO.sh";
    outShell2("denovo.sh\t$cmd", $cmd_file);
    qsub($cmd_file, $dir_assem, "10G", 1,
                    $queue, $project, $pro_name, 50);
    # |
    # ==========================================================================
    $pb_data = abs_path("$dir_assem/assemble.fasta");
    chdir("..");
}
# |
# ==============================================================================



# 对数据进行压缩
# ==============================================================================
# |
mkdir "Compress";
chdir("Compress");

outShell2("final $pb_data", "file.lst");

return if(!-e $kmer_file);

my $cmp_dir = abs_path("./");

$cmd  = "cd $cmp_dir && ";
$cmd .= "$SORT_FILE $pb_data $pb_data 5 && ";
$cmd .= "$CMPR compress -i file.lst  -m 3 -t 0.5 -n 1 -v 1 ";
$cmd .= "-g $kmer_file " if(-e $kmer_file);
$cmd .= "-k $kmer_size && ";
$cmd .= "echo done";

my $cmd_file = "$cmp_dir/COMPRESS.sh";
outShell2("compress.sh\t$cmd", $cmd_file);
qsub($cmd_file, $cmp_dir, "10G", 1,
                $queue, $project, $pro_name, 50);
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
        # pb file
        $pb_lst = $values[0] if($key eq "[pb_lst]");
        $filt_len = $values[0] if($key eq "[filt_len]");
        $genome_size = $values[0] if($key eq "[genome_size]");
        $data_type = $values[0] if($key eq "[pb_type]");
        # kmer
        ($kmer_file,$kmer_size) = @values if($key eq "[unique_kmer]");
        # qsub job
        $queue = $values[0] if($key eq "[queue]");
        $project = $values[0] if($key eq "[Project]");
        $pro_name = $values[0] if($key eq "[pro_name]");
        $job_num = $values[0] if($key eq "[max_job]");
        # strategy
        push(@strategys, "@values") if($key eq "[strategy]");
        # thread
        $thread = $values[0] if($key eq "[thread]");
    }
    $genome_size *= 10**6;
    $kmer_file = abs_path($kmer_file);
    $pb_lst = abs_path($pb_lst);
    $data_type ||= 2;
    close $cfg_hdl;
}
# |
# ==============================================================================
