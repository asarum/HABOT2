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


# Get parameters
# ==================================================================================================
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
# ==================================================================================================


# Global Variables
# ==================================================================================================
# |
my $SLEEP = 300;
# |
# ==================================================================================================


# Software Paths
# ==================================================================================================
# |
my $MERGEFQ = "perl $Bin/mergeFA.pl";
my $CMPR = "perl $Bin/../Compress/Compress.pl";
my $ALIGN = "perl $Bin/../Align/Align.pl";

my $FILTER  = "perl $Bin/filtAl.pl";
my $GRAPH   = "perl $Bin/buildGraph.pl";
my $LINK    = "perl $Bin/link.pl";

my $SORT_FILE = "perl $Bin/sortSeq.pl";

my $STAT = "$Bin/monitor stat ";
my $QSUB = "$Bin/monitor taskmonitor ";
my $UPDATE = "$Bin/monitor updateproject -p ";
my $RMPRO = "$Bin/monitor removeproject -p ";
my $CLEAN = "$Bin/monitor removeproject -d";
# |
# ==================================================================================================


# 对数据进行过滤和重命名
# ==================================================================================================
# |
mkdir ("Data");
mkdir ("Shell");

my $pb_data = abs_path("Data/data.fasta");

# 重命名
my $cmd = "$MERGEFQ $pb_lst $filt_len $pb_data \n";
system($cmd);
# |
# ==================================================================================================


my $index = -1;
@strategys = ($strategys[0], @strategys);
foreach(@strategys){
    print STDERR "$_\n";

    $index++;
    mkdir "Process_$index";
    chdir "Process_$index";
    
    # 目录结构
    # ==================================================================================================
    # |
    mkdir("Shell");
    mkdir("Assembly");
    
    my $dir_shell = abs_path("Shell");
    my $dir_align = abs_path("Align");
    my $dir_assem = abs_path("Assembly");
    # |
    # ==================================================================================================
 

    my($k_size, $min_ovl, $mode, $score, $min_len, $jump) = split;
    $min_len ||= 500;
    $jump ||= 1;
    
    # 对序列来比对
    # ==================================================================================================
    # |
    my $divide_size = int($genome_size/10**6)+1;
    $divide_size=400 if($divide_size>400);

    my $max_num = 3;	# 第一次，尽量节约时间
    $max_num = 10 if($index==1);
    $max_num = 5 if($index>1);

    $cmd  = "$ALIGN -k $k_size  -s $divide_size ";
    $cmd .= "-g $kmer_file -u 3 " if($k_size==$kmer_size);
    $cmd .= "-j 10 " if($mode==2);
    $cmd .= "-j $jump " if($mode==1);
    $cmd .= "-t $thread ";
    $cmd .= "-n $max_num ";
    $cmd .= "-s2 -1 -x $min_ovl -m $mode -d $dir_align $pb_data $pb_data\n";
    print STDERR "$cmd\n";
    system($cmd);
    # |
    # ==================================================================================================


    # 投递任务
    # ==================================================================================================
    # |
    qsubJobs("$dir_align/align.cfg");
    while (checkJobs($pro_name)==0) {
        sleep($SLEEP);
    }
    # |
    # ==================================================================================================


    # 数据聚类和组装
    # ==================================================================================================
    # |
    my $simi = 0.5;
    $simi = 0 if($data_type==1);

    $cmd  = "cd $dir_assem\n";
    $cmd .= "$FILTER $dir_align/align.al filter.al $min_len $score \n";
    $cmd .= "$GRAPH filter.al graph.info\n";
    $cmd .= "$LINK $pb_data short.lst graph.info assemble.fasta $simi && echo done\n";
    
    my $shell_denovo = "$dir_shell/denovo.sh";
    outShell($cmd, $shell_denovo);
    outShell("$shell_denovo:10G", "$dir_assem/config.txt");

    qsubJobs("$dir_assem/config.txt");
    while (checkJobs($pro_name)==0) {
        sleep($SLEEP);
    }
    # |
    # ==================================================================================================
    $pb_data = abs_path("$dir_assem/assemble.fasta");
    chdir("..");
}

# 对数据进行压缩
# ==================================================================================================
# |
mkdir "Compress";
chdir("Compress");

outShell("final $pb_data", "file.lst");

die "don't exists kmer file in compress.." if(!-e $kmer_file); 

my $cmp_dir = abs_path("./");
$cmd  = "cd $cmp_dir\n";
$cmd .= "$SORT_FILE $pb_data $pb_data 5\n";
$cmd .= "$CMPR compress -i file.lst  -m 3 -t 0.5 -n 1 -v 1 ";
$cmd .= "-g $kmer_file " if(-e $kmer_file);
$cmd .= "-k $kmer_size \n";
$cmd .= "echo done";

my $cmpr_sh = "$cmp_dir/compress.sh";

outShell($cmd, $cmpr_sh);
outShell("$cmpr_sh:5G","$cmp_dir/config.txt");
qsubJobs("$cmp_dir/config.txt");
# |
# ==================================================================================================


debug("Finish assembly");

# 从配置参数中取得参数
# ==================================================================================================
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
# ==================================================================================================


# 输出SHELL文件
# ==================================================================================================
# |
sub outShell{
  my($cmd, $outfile) = @_;
  open FO_,">$outfile" or die $!;
  print FO_ "$cmd";
  close FO_;
}
# |
# ==================================================================================================


# 提交任务
# ==================================================================================================
# |
sub qsubJobs{
    my $cfg_file = shift;
    my $info = "";
    
    my $cmd  = "$CLEAN\n";
    $cmd .= "$QSUB -i $cfg_file -p $pro_name -q $queue -P $project ";
    $cmd .= "-f 3 -s done -n $job_num -t $thread";

    $info = system($cmd);
}
# |
# ==================================================================================================


# 检查任务
# ==================================================================================================
# |
sub checkJobs{
    my($name) = @_;

    `$UPDATE $name`;
    my $lines = `$STAT -p $name`;
    my @info = split(/\n/, $lines);
    
    return 0 if(@info!=2);
    my @array = split(/\s+/, $info[1]);
    return 0 if(@array<7);
    
    my($done, $total) = @array[7,9];
    return 0 if($done !~ /^\d+/);    
   
    if($done == $total)
    {
        `$RMPRO $name`;
        return 1 ;
    }

    return 0;
}
# |
# ==================================================================================================

