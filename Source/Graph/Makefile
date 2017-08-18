GATB=../gatb-core-1.0.6-Linux
BWT=2bwt-lib-v1.0.0
DNA2=../DNA2

CPPFLAGS = -I$(GATB)/include/ -I${BWT} -I${DNA2}  -std=c++0x -O3 -g
LDFLAGS = -L$(GATB)/lib/ -L${DNA2} -L/nfs2/config/gcc/gcc-4.9.2/lib64/ -Wl,-R/nfs2/config/gcc/gcc-4.9.2/lib64  -lgatbcore -lhdf5 -ldl -lz -lpthread -std=c++0x -lz -lSeq
CXX	= g++
RM  = rm -f 


# |====================================================================================================
all: buildGraph buildIndex
.PHONY: all

buildGraph:	buildGraph.o 
			$(CXX)  buildGraph.o  $(LDFLAGS) ${CPPFLAGS}  -o buildGraph

buildIndex: buildIndex.o 
			$(CXX)  buildIndex.o  $(LDFLAGS) ${CPPFLAGS}  -o buildIndex

# |====================================================================================================

buildGraph.o: buildGraph.cpp
			$(CXX) $(LDFLAGS) ${CPPFLAGS} -c buildGraph.cpp

buildIndex.o: buildIndex.cpp
			$(CXX) $(LDFLAGS) ${CPPFLAGS} -c buildIndex.cpp

