#ifndef __DNA2__KmerBit__
#define __DNAT2__KmerBit__

#include <stdint.h>
#include <iostream>
#include <string>
#include <boost/dynamic_bitset.hpp>

using namespace std;
using namespace boost;

/// Basic kmer operations
class KmerBit{
public:
	/// Output the bitset to binary file
    ///
    /// @param bitset The input bitset to be output
    /// @param outfile The output filename
    /// @return void
    void outputBitSet(dynamic_bitset<> &bitset, string outfile);

    /// Output the kmer in string format
    ///
    /// @param bitset The input bitset to be output
    /// @param kmer_size the kmer size
    /// @param outfile The output filename
    /// @return void
    void outputKmer(dynamic_bitset<> &bitset, int kmer_size, string outfile);

    /// input the bitset from binary file
    ///
    /// @param infile The input filename
    /// @param bitset The bitset to record the kmer
    void inputBitSet(string infile, dynamic_bitset<> &bitset);
    
    /// record kmer to bitset
    ///
    /// @param kmer the kmer to record
    /// @param bitset the bitset to record the kmer
    void recordKmer(uint64_t kbit, dynamic_bitset<> &bitset);

    /// clean kmer in bitset
    ///
    /// @param kmer the kmer to unset
    /// @param bitset the bitset to record the kmer
    void unsetKmer(uint64_t kbit, dynamic_bitset<> &bitset);

    /// judge if the kmer exists in the bitset
    ///
    /// @param kbit the kmer in uint_64_t to store
    /// @param bitset
    /// @return if exists in bitset, return true
    /// @return if not exists in bitset, return false
    bool isExists(uint64_t kbit, dynamic_bitset<> &bitset);

    /// initial the size of bitset
    ///
    /// @param bitset the bitset to be initial
    /// @param kmer_size the length of k-mer
    void initialBitSet(dynamic_bitset<> &bitset,int kmer_size);


};

#endif /* defined(__DNAT2__KmerBit__) */