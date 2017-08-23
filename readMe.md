Contact: Dongliang Zhan <zhandongliang@1gene.com.cn>

A test website based on the Galaxy framework is available at:

http://61.130.10.147:9010/

username: test@1gene.com.cn

password: 1gene.com.cn

## Assembly Method

We developed a hybrid assembly software name "HABOT2" to assemble Illumina data and PacBio data. This software conatins 3 main modules: a.graph module, b.align module, c.Denovo module.


### Graph module

By couting the k-mer frequency from Illumina reads, we can get the unique k-mer by the distribution of frequency. The unique k-mer is a sequence of length k that only appear only once in a haploid genome[7]. This module count the k-mer by using Jellyfish[8], and make the k-mer that occurrence less than 1.5xpeak as unique k-mer. By using the unique k-mer, we can do alignment very quickly and accurracy without the repeat fluenced.

The usage of this module:

Name
        Graph.pl  --The De novo tool to build k-mer graph

Usage
        Graph.pl <command> [arguments]

        Command should be one of the following command. Arguments depend on specific command.

        Command List:
                    count   Record k-mer and related occurrence by jellyfish
                            Arguments:
                              -i <FILE>       the file list to count kmer
                              -k <INT>        the k-mer size to store occupied k-mer [17]

                    graph   Build graph by using GATB tookit(for Lordec)
                              Arguments:
                              -i <FILE>       the kmer table file with format "ATGC 1"
                              -m <INT>        the mininum occurrence of kmer [3]
                              -x <INT>        the maxinum occurrence of kmer [-1]
                              -k <INT>        the k-mer size

                    bit     Record k-mer into bitset, this method is for k<=17.
                              -i <FILE>       the kmer table file with format "ATGC 1"
                              -m <INT>        the mininum occurrence of kmer [3]
                              -x <INT>        the maxinum occurrence of kmer [-1]
                              -k <INT>        the k-mer size to store occupied k-mer [17]

                    pipe    Combine step(s) above
                              -i <FILE>       the file list 
                              -m <INT>        the mininum occurrence of kmer [3]
                              -k <INT>        the k-mer size to store occupied k-mer [17]
                              -s <INTs>       the step to do
                                              1: count k-mer by jellyfish

                                              2: record unique k-mer into .h5 file
                                              3: record unique k-mer into .bit file

                                              4: record all k-mer into .h5 file
                                              5: record all k-mer into .bit file

                                              6: record all kmer into .bit with -m is 0.5 the peak

                    -d      The output directory

Example
    For k=17, we recommend:

      perl Graph.pl pipe -i fq.lst -m 2 -k 17 -s 1,3,5 -d Kmer_17

    For k>17, we recommend:

      perl Graph.pl pipe -i fq.lst -m 2 -k 23 -s 1,2,4 -d Kmer_23
  
### Align module
We developed an alignment software that can align the long reads very fast. This software contains the following steps:

(1) Build index for the reference by BWT[9] and load unique k-mer.

(2) Do alignment:

For each query, we firstly find anchors by geting the unique kmer between query and reference. Then compare each target from reference and get the similarity by LCS algorithm[10].

The usage of this module:

perl Align.pl 
Name
        Align.pl  --The Alignment Tool

Usage
        perl Align.pl [arguments] <reference.fa> <query.fa>

        Argument List:
                      -g <FILE>       the unique kmer(.h5 or .bit)
                      -k <INT>        the kmer size of the unique graph[17]
                      -u <INT>        the min unique kmer[3]

                      -s <INT>        split the reference file, in unit of M[100].
                      -s2<INT>        split the query file, in unit of M[1000].

                      -x <INT>        the scope to align[-1]
                      -j <INT>        the jump length to get kmer[1]
                      -n <INT>        max align number for query [20]

                      -t <INT>        thread number[4]
                      -m <INT>        align mode[1]
                                      1. align with LCS,for uncrrected reads
                                      2. align with kmer, for corrected reads

                      -c <FILT>       the config file for qsub [align.cfg]
                      -d <DIR>        the output directory [Align]

                      -q <INT>        sort result[2]
                                      1. by query name
                                      2. by reference name

Example
    perl Align -g k17.bit -k 17 -f 5 -u 3 -n 3 ref.fa query.fa
Denovo module
This module contains the align module and polish module that align the contig assembled by Illumina data to the PacBio reads, and build the pacbio graph via the alignment result. Then we get the assembly backbone by the graph.

The usage of this module:

perl Denovo.pl <input.cfg>
the input.cfg demo:

```
# the input file list, in fasta format
[pb_lst]    file.lst

# Data type:
# 1：the uncorrected data
# 2：the corrected data
[pb_type] 2

# filter read length
[filt_len]      1000

# genome size in Magebase
[genome_size]   11

# unique kmer, kmer size
[unique_kmer]   kmer_15.bit 15

# Align parameters
# Col.1，kmer size
# Col.2：the scope for find anchor，-1 is for all length
# Col.3：align mode
#         1：for uncorrected reads
#         2：for corrected reads
# Col.4：filter score below this value
[strategy] 15 -1    2   0.8 
[strategy] 33 -1    2   0.8
[strategy] 35 1000  1   0.9 
[strategy] 35 -1    1  0.9    

# project name
[pro_name] yeast_test

# qsub parameters
[queue] dna.q,rna.q,reseq.q
[Project] og
[max_job] 50
[thread] 8
```
We used two stategy to reduce error connections and deal conflicts:

    (1) Using the unique kmer to do alignment to avoid the repeat region alignment.

    (2) Give up the connection when we face below situation:

        (2a) Node A's best connection Node is B
        (2b) Node B's best connection Node is C
        (2c) Give up connection from A to B if B has no alignment with C`

### Remove Dupplication
This module used the unique k-mer to remove dupplication.

The usage of this module:

Name
        Compress.pl  --The compress module for fastq(a) files

Usage
        perl Compress.pl <command> [arguments]

        Command should be one of the following command. Arguments depend on specific command.

        Command List:
                    compress  Compress reads
                              Arguments:
                              -i <FILE>       the file list with format like:
                                              Out_prefix read_1 read_2
                                              Out_prefix read_n

                              -g <FILE>       the k-mer file from reads(.h5 or .bit)
                              -k <INT>        the k-mer size
                              -m <INT>        the min kmer num in read[3]

                              -t <FLOAT>      trim the reads if (occupied_kmer/unique_kmer)>=this_value[0.7]
                              -n <INT>        thread number [8]

                              -v <INT>        output the log file[0]
                                              0: don't record the log
                                              1: record the log

                    pipe  Compress reads with different insert size
                              -i <FILE>       the file list with paired-end or mate reads
                                              read_1  500
                                              read_2  500
                                              read_3  1000
                                              read_4  1000

                              -g <FILE>       the k-mer file from reads(.h5 or .bit)
                              -k <INT>        the k-mer size
                              -m <INT>        the min kmer num in read[3]

                              -t <FLOAT>      trim the reads if (occupied_kmer/unique_kmer)>=this_value[0.7]
                              -n <INT>        thread number [8]

Example
     Compress data:
        perl Compress.pl compress -i file.lst -g kmer_17.h5 -k 17 -m 3 -t 0.7 -n 16
