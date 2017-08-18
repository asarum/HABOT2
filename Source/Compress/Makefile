GATB=../gatb-core-1.0.6-Linux
BWT=2bwt-lib-v1.0.0
DNA=../DNA2

CPPFLAGS = -I$(GATB)/include/ -I${BWT} -I${DNA}  -std=c++0x -O3 -g
LDFLAGS = -L$(GATB)/lib/ -L${DNA} -L/nfs2/config/gcc/gcc-4.9.2/lib64/ -Wl,-R/nfs2/config/gcc/gcc-4.9.2/lib64  -lgatbcore -lhdf5 -ldl -lz -lpthread -std=c++0x -lz -lSeq
CXX	= g++
RM  = rm -f 

# |====================================================================================================
all: compress
.PHONY: all

compress:	compress.o 
			$(CXX) compress.o  $(LDFLAGS) ${CPPFLAGS}  -o compress

# |====================================================================================================

compress.o:	compress.cpp
			$(CXX) $(LDFLAGS) ${CPPFLAGS} -c compress.cpp

