GATB=../gatb-core-1.0.6-Linux
BWT=2bwt-lib-v1.0.0
DNA=../DNA2

CPPFLAGS = -I$(GATB)/include/ -I${BWT} -I${DNA}  -std=c++0x -O3 -g
LDFLAGS = -L$(GATB)/lib/ -L/nfs2/config/gcc/gcc-4.9.2/lib64/ -Wl,-R/nfs2/config/gcc/gcc-4.9.2/lib64  -lgatbcore -lhdf5 -ldl -lz -lpthread -std=c++0x -lz 
CXX	= g++
RM  = rm -f 

# |====================================================================================================
objects = ../DNA2/Kmer.o ../DNA2/SeqTool.o ../DNA2/gzstream.o ../DNA2/KmerBit.o

# |====================================================================================================
all: UniKmer kmer2tag getKmer
.PHONY: all

UniKmer:	UniKmer.o ${objects}
			$(CXX) ${objects} UniKmer.o  $(LDFLAGS) ${CPPFLAGS}  -o UniKmer

kmer2tag:	kmer2tag.o  ${objects}
			$(CXX) ${objects} getMarker.o  $(LDFLAGS) ${CPPFLAGS}  -o kmer2tag

getKmer:    getKmer.o ${objects}
			$(CXX) ${objects} getKmer.o  $(LDFLAGS) ${CPPFLAGS}  -o getKmer

# |====================================================================================================

UniKmer.o:	UniKmer.cpp
			$(CXX) $(LDFLAGS) ${CPPFLAGS} -c UniKmer.cpp

kmer2tag.o: kmer2tag.cpp
			$(CXX) $(LDFLAGS) ${CPPFLAGS} -c kmer2tag.cpp

getKmer.o:  getKmer.cpp
			$(CXX) $(LDFLAGS) ${CPPFLAGS} -c getKmer.cpp
