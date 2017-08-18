GATB=../gatb-core-1.0.6-Linux
BWT=2bwt-lib-v1.0.0
DNA=../DNA2

CPPFLAGS = -I$(GATB)/include/ -I${BWT} -I${DNA}   -std=c++0x -O3 -g
LDFLAGS = -L$(GATB)/lib/ -L$(DNA) -Wl,-R$(DNA) -L/nfs2/config/gcc/gcc-4.9.2/lib64/ -Wl,-R/nfs2/config/gcc/gcc-4.9.2/lib64  -lgatbcore -lhdf5 -ldl -lz -lpthread -std=c++0x -lz -lSeq 
CXX	= g++
RM  = rm -f 

# |====================================================================================================
objects =  ${BWT}/*.o 

# |====================================================================================================
all: align_bwt align_bwt_s
.PHONY: all

align_bwt:	align_bwt.o ${objects} 
	$(CXX) ${objects} align_bwt.o  $(LDFLAGS) ${CPPFLAGS}  -o align_bwt

align_bwt_s: align_bwt_s.o ${objects}
	$(CXX) ${objects} align_bwt_s.o $(LDFLAGS) ${CPPFLAGS}  -o align_bwt_s

test:	test.o ${objects}
	$(CXX) ${objects} test.o  $(LDFLAGS) ${CPPFLAGS}  -o test

# |====================================================================================================
align_bwt.o: align_bwt.cpp
	$(CXX) $(LDFLAGS) ${CPPFLAGS} -c align_bwt.cpp

align_bwt_s.o: align_bwt_s.cpp
	$(CXX) $(LDFLAGS) ${CPPFLAGS} -c align_bwt_s.cpp
