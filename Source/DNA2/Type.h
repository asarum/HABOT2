//
//  Type.h
//  DNATool
//
//  Created by lardo on 14-1-2.
//  Copyright (c) 2014年 lardo. All rights reserved.
//

///@file
///@brief   Type and struct definition

#ifndef DNA2_Type_h
#define DNA2_Type_h

#include <vector>
#include <unordered_set>
#include <set>
#include <stdint.h>
#include <unordered_map>
#include <string>

using namespace std;

/// The positions fo the same k-mer between sequences
struct coord{
    long pos1;  ///<the position from sequence1.
    long pos2;  ///<the position from sequence2.

    ///A constructor
    coord(long p1,long p2){
        pos1 = p1;
        pos2 = p2;
    }

    coord(const coord& c){
        pos1 = c.pos1;
        pos2 = c.pos2;
    }

    coord(){}
};

/// The alignment infomation
struct Conn_info {
    uint32_t len1, len2;
    uint32_t ovl=0;
    uint32_t pos1, pos2;

    bool is_rev1 = false; // for seq1
    float block  = 0;
    float match  = 0;

    coord start, end;
};

static char const bases[5] = {'A','C','G','T','N'};
static char const c_base[5]= {'T','G','C','A','N'};
static char const alphabet[128] =
{
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,//15
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,//31
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,//47
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,//63
    4, 0, 4, 1, 4, 4, 4, 2, 4, 4, 4, 4, 4, 4, 4, 4,//79
    4, 4, 4, 4, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,//95
    4, 0, 4, 1, 4, 4, 4, 2, 4, 4, 4, 4, 4, 4, 4, 4,//111
    4, 4, 4, 4, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4 //127
};

typedef vector<coord>  Matrix;
typedef unordered_map<uint64_t,vector<uint64_t>> KmerMap;
typedef unordered_set<string> StrSet;
typedef unordered_map<string,string> StrMap;
typedef unordered_map<string,StrSet*> StrSetMap;

#endif
