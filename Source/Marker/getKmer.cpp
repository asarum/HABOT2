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

// Global input parameters
// =============================================================================
// |
string bit_file;                /**< the input bit file of unique k-mers */
string files;                   /**< the file list */
string output="sample.log";     /**< the output file */

string out_all;
string out_com;
string out_uni;
// |
//  ============================================================================


// Get parameters
// =============================================================================
// |
void help()
{
    cerr<<"Get k-mers stat by compare with others"<<endl;
    cerr<<endl;
    cerr<<"-i: the kmer bit file that contain k-mers"<<endl;
    cerr<<"-f: the file list that contain other bit files"<<endl;
    cerr<<"-o: the output file [unique.bit]\n\n";
    cerr<<"options:"<<endl;
    cerr<<"-a: output the combine bitset\n";
    cerr<<"-c: output the common bitset\n";
    cerr<<"-u: output the unique bitset\n";
    cerr<<"Example:"<<endl;
    cerr<<"    getKmer  -i k17.bit -f file.lst -o unique.bit "<<endl;
    exit(EXIT_FAILURE);
 }


void showParam()
{
    cerr<<"getKmer"<<endl;

    cerr<<"-i:"<<bit_file<<endl;
    cerr<<"-f:"<<files<<endl;
    cerr<<"-o:"<<output<<endl;
    cerr<<"options:"<<endl;
    cerr<<"-u:"<<out_uni<<endl;
    cerr<<"-c:"<<out_com<<endl;
    cerr<<"-a:"<<out_all<<endl;
 }


void getParam(int argc,char ** argv)
{
    int ch;
    while((ch = getopt(argc,argv,"i:f:o:u:c:a:"))!=-1)
    {
        switch(ch){
            case 'i':
                bit_file = optarg;
                break;
            case 'f':
                files = optarg;
                break;
            case 'o':
                output = optarg;
                break;
            case 'u':
            	out_uni = optarg;
            	break;
            case 'a':
            	out_all = optarg;
            	break;
            case 'c':
            	out_com = optarg;
            	break;

        }
    }
    if(bit_file.size()==0||files.size()==0){
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
           

/**tool**/
Kmer_Tool kmer_tool;
KmerBit bit_tool;
// |
// =============================================================================


int main (int argc, char* argv[])
{
    getParam(argc,argv);
    showParam();

    cerr<<"loading unique kmer:"<<endl;
    bit_tool.inputBitSet(bit_file, kmer_freq);
    long kmer_num = kmer_freq.count();
    cerr<<bit_file<<" "<<kmer_num<<endl;

    //  get stats
    //  ========================================================================
    string file;
    ifstream in_hdl(files);
    ofstream log_hdl(output);
    log_hdl<<"# bit1 bit2 kmer1 kmer2 common"<<endl;
    while(getline(in_hdl,file))
    {   
        if(file.size()<3)
            continue;
        dynamic_bitset<> other_freq(10);
        bit_tool.inputBitSet(file, other_freq);
        long kmer_num2 = other_freq.count();
        
        cerr<<"other "<<file<<" "<<kmer_num2<<endl;
        // get common kmer
    	other_freq &= kmer_freq;
		long kmer_num3 = other_freq.count();
        
        log_hdl<<bit_file<<"\t"<<file<<"\t";
        log_hdl<<kmer_num<<"\t"<<kmer_num2<<"\t"<<kmer_num3<<endl;

    }
    in_hdl.close();
    log_hdl.close();
    // |
    // =========================================================================
    


    
    //  get unique kmer
    //  ========================================================================
    if(out_uni.size()!=0)
    {
        dynamic_bitset<> out_freq(10);
    	cerr<<"get unique kmers.."<<endl;
	    in_hdl.open(files);
	    while(getline(in_hdl,file))
	    {        
            cerr<<"parsing: "<<file<<endl;
            if(file.size()<3)
                continue;

	        dynamic_bitset<> other_freq(10);
	        bit_tool.inputBitSet(file, other_freq);
	        other_freq.flip();
	        out_freq = other_freq & kmer_freq;
	        cerr<<"After "<<file<<": "<<out_freq.count()<<endl;
	    }
	    in_hdl.close();
        bit_tool.outputBitSet(out_freq, out_uni);
        // out_freq.resize(10,0);
    }
    
    // |
    // =========================================================================


    //  get common kmer
    //  ========================================================================
    if(out_com.size()!=0)
    {
        dynamic_bitset<> out_freq(10);
    	cerr<<"get common kmers.."<<endl;
	    in_hdl.open(files);
	    while(getline(in_hdl,file))
	    {       
            if(file.size()<3)
                continue;

	        dynamic_bitset<> other_freq(10);
	        bit_tool.inputBitSet(file, other_freq);
	        out_freq = other_freq & kmer_freq;
	        cerr<<"After "<<file<<": "<<out_freq.count()<<endl;
	    }
	    in_hdl.close();
        bit_tool.outputBitSet(out_freq, out_com);
        // out_freq.resize(10,0);
    }
   
    // |
    // =========================================================================


	//  get all kmer
    //  ========================================================================
    if(out_all.size()!=0)
    {
        dynamic_bitset<> out_freq(10);
    	cerr<<"get all kmers.."<<endl;
	    in_hdl.open(files);
	    while(getline(in_hdl,file))
	    {        
            if(file.size()<3)
                continue;

	        dynamic_bitset<> other_freq(10);
	        bit_tool.inputBitSet(file, other_freq);
	        out_freq = other_freq | kmer_freq;
	        cerr<<"After "<<file<<": "<<out_freq.count()<<endl;
	    }
	    in_hdl.close();
        bit_tool.outputBitSet(out_freq, out_all);
        // out_freq.resize(10,0);
    }
   
    // |
    // =========================================================================    
}
