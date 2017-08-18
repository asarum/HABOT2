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
string bit_file;        /**< the input graph file of unique k-mers */

string infile;          /**< the input file */
string output;          /**< the output file */

int thread_num =4;      /**< the thread number */
int kmer_size = 0;      /**< the kmer size of kmer table */
// |
//  ============================================================================


// Get parameters
// =============================================================================
// |
void help()
{
    cerr<<"get reads with unique marker"<<endl;
    cerr<<endl;

    cerr<<"-k:  the length of k-mer"<<endl;
    cerr<<"-i:  the bit file contain unique k-mers"<<endl;
    cerr<<"-f:  the file list contain short reads"<<endl;
    cerr<<"-o:  the output reads contain unique marker"<<endl;
    cerr<<"-t:  the thread number [4]"<<endl;
    cerr<<endl;

    cerr<<"Example:"<<endl;
    cerr<<"    kmer2tag  -i k17.bit -k 17 -f file.lst -o unique.tag "<<endl;
    exit(EXIT_FAILURE);
 }


void showParam()
{
    cerr<<"getMarker"<<endl;

    cerr<<"-i:"<<bit_file<<endl;
    cerr<<"-k:"<<kmer_size<<endl;
    cerr<<"-f:"<<infile<<endl;
    cerr<<"-o:"<<output<<endl;

    cerr<<"-t:"<<thread_num<<endl;
 }


void getParam(int argc,char ** argv)
{
    int ch;
    while((ch = getopt(argc,argv,"i:k:f:o:t:"))!=-1)
    {
        switch(ch){
            case 'i':
                bit_file = optarg;
                break;
            case 'k':
                kmer_size = atoi(optarg);
                break;
            case 'f':
                infile = optarg;
                break;
            case 'o':
                output = optarg;
                break;
            case 't':
                thread_num = atoi(optarg);
                break;
        }
    }
    if(infile.size()==0||bit_file.size()==0||kmer_size==0)
    {
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

/** store record kmer **/
dynamic_bitset<> set_freq(10);
int kmer_size2 = 17;

/**tool**/
ISynchronizer* synchro;
Kmer_Tool kmer_tool;
KmerBit bit_tool;
// |
// =============================================================================


// Initial an empty bitset to store record kmer
// =============================================================================
// |
void initBitset()
{
    kmer_size2 = kmer_size;
    if(kmer_size2>17)
        kmer_size2 = 17;

    bit_tool.initialBitSet(set_freq, kmer_size2);
}
// |
// =============================================================================



// Is the Kmer exists in input kmer graph
// =============================================================================
// |
bool isExists(string kmer)
{
    uint64_t kbit = kmer_tool.getMinBit(kmer);
    return bit_tool.isExists(kbit, kmer_freq);
    
    return true;
}
// |
// =============================================================================


// get the seq info
// =============================================================================
// |
long parseSeq(string sequence, int k)
{
    long len = sequence.length();

    long match_num = 0;

    for(int i=0;i<=len-k; i++)
    {
        string kmer = sequence.substr(i,k);
        int is_exists = int(isExists(kmer));
        match_num += is_exists;
    }
    
    return match_num;
}
// |
// =============================================================================


// record kmer in bitset
// =============================================================================
// |
void setKmer(const string &kmer)
{
    string kmer1 = kmer.substr(0,kmer_size2);
   
    uint64_t bit = kmer_tool.getMinBit(kmer1);
    set_freq[bit] = 1;
}
// |
// =============================================================================



// record kmer in bitset
// =============================================================================
// |
void record(string sequence)
{
    long len = sequence.length();
    for(int i=0;i<=len-kmer_size;i++)
    {
        string kmer = sequence.substr(i,kmer_size);
        if(isExists(kmer))
            setKmer(kmer);
    }
}
// |
// =============================================================================


int main (int argc, char* argv[])
{
    getParam(argc,argv);
    showParam();

    cerr<<"loading unique kmer:"<<endl;
    // =========================================================================
    // |
    initBitset();
    bit_tool.inputBitSet(bit_file, kmer_freq);
    cerr<<"kmer num: "<<kmer_freq.count()<<endl;

    // string kmer_file = output+".tag";
    // bit_tool.outputKmer(kmer_freq, kmer_size, kmer_file);
    // |
    // =========================================================================

    //  parse read
    //  ========================================================================
    string file;
    ofstream out_hdl(output);
    ifstream in_hdl(infile);
    while(getline(in_hdl,file))
    {    
        BankFasta bank (file);
        Dispatcher dispatcher (thread_num);
        synchro = System::thread().newSynchronizer();
        dispatcher.iterate (bank.iterator(), [&] (const Sequence& seq)
        {
            string comment = seq.getComment();
            string read = seq.toString();

            string info;
            long match_num = parseSeq(read, kmer_size);
            
            // record(read);
            LocalSynchronizer sync (synchro);
            out_hdl<<">"<<comment<<" match:"<<match_num<<"|len:"<<read.size()<<endl;
            out_hdl<<read<<endl;
            return;
        });
    }
    // |
    // =========================================================================
    // cerr<<"match kmer: "<<set_freq.count()<<endl;
}
