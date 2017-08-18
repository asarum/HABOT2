use strict;
use warnings;
use FindBin qw($Bin);
use Getopt::Long;
use File::Basename;
use Cwd qw(abs_path getcwd);

BEGIN {
    push (@INC,"$Bin");
}
use Qsub;
use SeqIO;

# Get parameters
# ==============================================================================
# |
die "perl $0 <input.cfg>\n" if(@ARGV==0);
my($cfg_file) = @ARGV;

# contig
my $contig;

# min_occ
my $min_occ = 1;

# min dist
my $min_dist = -1000;

# pb file
my($genome_size, $pb_lst, $filt_len);

# kmer
my($kmer_file, $kmer_size);

# sge
my($queue, $project, $pro_name, $job_num);

# align strategys
my($k_size, $min_ovl, $mode, $score);

# thread
my $thread = 8;

parseCfg($cfg_file);
# |
# ==============================================================================



# Software Paths
# ==============================================================================
# |
my $MERGE = "perl $Bin/mergeFiles.pl";
my $ALIGN = "perl $Bin/Align.pl";

my $FILTER  = "perl $Bin/filtAl.pl";
my $CONVT = "perl $Bin/al2scf.pl";
my $BUILD  = "perl $Bin/buildGraph_s.pl";
my $LINK = "perl $Bin/link_s.pl ";

# |
# ==============================================================================


# 对数据进行过滤和重命名
# ==============================================================================
# |
mkdir ("Data");
my $dir_data = abs_path("Data");

my $pb_data = abs_path("Data/data.fasta");

my $contig2 = abs_path("Data/contig.fasta");
my $contig_lst = abs_path("Data/contig.lst");
outShell2($contig, $contig_lst);

my $cmd = "$MERGE $contig_lst 100 $contig2\n";
$cmd   .= "$MERGE $pb_lst $filt_len $pb_data \n";

system($cmd);
# |
# ==============================================================================


# 比对
# ==============================================================================
# |
my $dir_align = abs_path("Align");

my $divide_size = int($genome_size/10**6)+1;
$divide_size=400 if($divide_size>400);

$cmd  = "$ALIGN -k $k_size  -s $divide_size -t $thread ";
$cmd .= "-g $kmer_file -u 3 -n 2 -x $min_ovl ";
$cmd .= "-m $mode -d $dir_align $contig2 $pb_data\n";

debug($cmd);
system($cmd);
# |
# ==============================================================================


# 进行scaffold构建
# ==============================================================================
# |
my $dir_assem = abs_path("Scaffold");
mkdir($dir_assem);
chdir($dir_assem);

# 命令
$cmd  = "cd $dir_assem && ";
# 去掉质量低的比对
$cmd .= "$FILTER $dir_align/align.al filter.al 300 $score && ";
# 将比对信息转化为连接信息
$cmd .= "$CONVT filter.al link.info && ";
# 构建连接
$cmd .= "$BUILD link.info graph.info $min_occ $min_dist && ";
# 输出连接
$cmd .= "$LINK $contig2 graph.info scaffold.fasta ";

# config 文件
my $cfg = "SCAFF.SH";
outShell2("scaffold.sh\t$cmd", $cfg);

# 提交任务
qsub($cfg, $dir_assem, "5G", 1,
                $queue, $project, $pro_name, 50);

# |
# ==============================================================================


# 清理数据
# ==============================================================================
# |
`rm -r $dir_data`;
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
        $contig = $values[0] if($key eq "[contig]");

        # min occ
        $min_occ = $values[0] if($key eq "[min_occ]");

        # min distant
        $min_dist = $values[0] if($key eq "[min_dist]");

        # pb file
        $pb_lst = $values[0] if($key eq "[pb_lst]");
        $filt_len = $values[0] if($key eq "[filt_len]");
        $genome_size = $values[0] if($key eq "[genome_size]");

        # kmer
        ($kmer_file,$kmer_size) = @values if($key eq "[unique_kmer]");

        # qsub job
        $queue = $values[0] if($key eq "[queue]");
        $project = $values[0] if($key eq "[Project]");
        $pro_name = $values[0] if($key eq "[pro_name]");
        $job_num = $values[0] if($key eq "[max_job]");

        # thread
        $thread = $values[0] if($key eq "[thread]");

        # strategy
    	($k_size, $min_ovl, $mode, $score) = @values if($key eq "[strategy]");
    }
    $contig = abs_path($contig);
    $genome_size *= 10**6;
    $kmer_file = abs_path($kmer_file);
    $pb_lst = abs_path($pb_lst);
    close $cfg_hdl;
}
# |
# ==============================================================================
