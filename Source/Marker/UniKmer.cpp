#include "def.h"

#include "gzstream.h"
#include "Kmer.h"
#include "SeqTool.h"
#include "KmerBit.h"
#include <gatb/gatb_core.hpp>
#include <unordered_map>
#include <vector>

#define span 31 

using namespace std;

/******************************************************************************/
/*           Compare between 2 kmer set                                       */
/*                                                                            */
/* 1.get unique kmer for each set                                             */
/* 2.get common kmer from kmer set                                            */
/*                                                                            */
/******************************************************************************/


// Global parameters
// =============================================================================
// |
string bit_file1;               
string bit_file2;

string output_uni1;
string output_uni2;
string output_comm;
// |
//  ============================================================================


// Get parameters
// =============================================================================
// |
void help()
{
    cerr<<"Get unique k-mers by compare with other kmer set"<<endl;
    cerr<<endl;
    cerr<<"-a: the kmer bit file1"<<endl;
    cerr<<"-b: the kmer bit file1"<<endl;
    cerr<<"-c: the output common kmer\n";
    cerr<<"-j: the output unique kmer of file1\n";
    cerr<<"-k: the output unique kmer of file2\n";

    cerr<<"Example:"<<endl;
    cerr<<"    UniKmer -a female.bit -b male.bit ";
    cerr<<"-c common.bit -j female_uni.bit -k male_uni.bit"<<endl;
    exit(EXIT_FAILURE);
 }


void showParam()
{
    cerr<<"UniKmer"<<endl;

    cerr<<"-a:"<<bit_file1<<endl;
    cerr<<"-b:"<<bit_file1<<endl;
    cerr<<"-c:"<<output_comm<<endl;
    cerr<<"-j:"<<output_uni1<<endl;
    cerr<<"-k:"<<output_uni2<<endl;
 }


void getParam(int argc,char ** argv)
{
    int ch;
    while((ch = getopt(argc,argv,"a:b:c:j:k:"))!=-1)
    {
        switch(ch){
            case 'a':
                bit_file1 = optarg;
                break;
            case 'b':
                bit_file2 = optarg;
                break;
            case 'c':
                output_comm = optarg;
                break;
            case 'j':
                output_uni1 = optarg;
                break;
            case 'k':
                output_uni2 = optarg;
                break;
        }
    }
    if(bit_file1.size()==0||bit_file2.size()==0){
        showParam();
        cerr<<"Please check your parameters"<<endl<<endl;
        help();
        exit(EXIT_FAILURE);
    }
}
// |
//  ============================================================================



// Kmer Objects and Tools
// =============================================================================
// |

/** the input kmer **/
dynamic_bitset<> kmer_freq(10);
dynamic_bitset<> other_freq(10);
         

/**tool**/
Kmer_Tool kmer_tool;
KmerBit bit_tool;
// |
// =============================================================================



int main (int argc, char* argv[])
{
    getParam(argc,argv);
    showParam();

    cerr<<"loading kmer bit:"<<endl;
    bit_tool.inputBitSet(bit_file1, kmer_freq);
    bit_tool.inputBitSet(bit_file2, other_freq);
    
    long kmer_num1 = kmer_freq.count();
    long kmer_num2 = other_freq.count();
    cerr<<"initial kmer num in "<<bit_file1<<" : "<<kmer_num1<<endl;
    cerr<<"initial kmer num in "<<bit_file2<<" : "<<kmer_num2<<endl;
    


    //  Get Common Kmer
    //  ========================================================================
    // |
    dynamic_bitset<> out_freq(10);

    out_freq = kmer_freq & other_freq;

    long kmer_num = out_freq.count();
    cerr<<"common kmer: "<<kmer_num<<endl;
    if(output_comm.size()!=0)
        bit_tool.outputBitSet(out_freq, output_comm);
    // |
	// =========================================================================


    //  Get Unique Kmer for A
    //  ========================================================================
    // |
    other_freq.flip();
    out_freq = kmer_freq & other_freq;
    other_freq.flip();

    kmer_num = out_freq.count();
    cerr<<"unique kmer in "<<bit_file1<<": "<<kmer_num<<endl;
    if(output_uni1.size()!=0)
        bit_tool.outputBitSet(out_freq, output_uni1);
    // |
	// =========================================================================


	//  Get Unique Kmer for B
    //  ========================================================================
    // |
    kmer_freq.flip();
    out_freq = kmer_freq & other_freq;
    kmer_freq.flip();

    kmer_num = out_freq.count();
    cerr<<"unique kmer in "<<bit_file2<<": "<<kmer_num<<endl;
    if(output_uni2.size()!=0)
        bit_tool.outputBitSet(out_freq, output_uni2);
    // |
	// =========================================================================
}
