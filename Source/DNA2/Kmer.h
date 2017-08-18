//
//  Kmer.h
//  DNATool
//
//  Created by lardo on 13-12-29.
//  Copyright (c) 2013年 lardo. All rights reserved.
//

///@file
///@brief   the Kmer class

#ifndef __DNA2__Kmer__
#define __DNA2__Kmer__

#include <stdint.h>
#include <string>

using namespace std;

/// Basic kmer operations
class Kmer{
    
public:    
    /// Convert kmer from string format to uint64_t
    ///
    /// @param kmer A kmer in string format
    /// @return The uint_64 formate of the kmer
    /// @note The kmer length <=31
    uint64_t kmer2bit(const string &kmer);
    
    /// Convert kmer from uint64_t format to string format
    ///
    /// @param kbit A kmer of uint64_t format
    /// @param kmer_size the length of kmer
    /// @return A string formate of the kmer
    string bit2kmer(uint64_t kbit, int kmer_size);
    
    /// reverse and completement of k-mer
    ///
    /// @param  kbit    The bit pattern of k-mer as input
    /// @param  ksize   The k-mer length
    /// @return A bit of reverse completement of kbit
    /// @note   The k-mer length <=31
    uint64_t get_reverse_complement_kbit(uint64_t kbit, int ksize);

    /// Convert kmer from string format to uint64_t regardless of strand
    ///
    /// @param kmer A kmer string
    /// @return The mimimus uint_64 formate of the kmer
    /// @note the kmer length <=31
    uint64_t getMinBit(const string &kmer);
    
};

#endif /* defined(__DNAT2__Kmer__) */

