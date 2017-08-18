####################################################################
#
#   Modification History
#
#   Date   : 4th July 2014
#   Author : Dongliang Zhan
#
####################################################################

CC     =	gcc
LIBS   = 	-lz  -lpthread -lm
BOOST  = 	-lboost_regex -lboost_system -I /nfs/config/boost/include  -L \
			/nfs/config/boost/lib 
CFLAGS = 	--std=gnu++0x -fPIC

# Alias
# |
# ===================================================================================================
basic  =  Kmer.o KmerBit.o SeqToo.o 
# |
# ===================================================================================================


# Executable file
# |
# ===================================================================================================
all:  Kmer.o SeqTool.o KmerBit.o  libSeq.so.1.0
.PHONY: all

# |
# ===================================================================================================

# Alias
# |
# ===================================================================================================

Kmer.o: Kmer.h Type.h Kmer.cpp 
	${CC}  ${CFLAGS}  ${LIBS} ${LDFLAGS}  -c Kmer.cpp

SeqTool.o: SeqTool.h SeqTool.cpp SW.h
	${CC}  ${CFLAGS}  ${LIBS}  -c SeqTool.cpp 

KmerBit.o: KmerBit.h KmerBit.cpp 
	${CC}  ${CFLAGS}  ${LIBS} ${BOOST}  -c KmerBit.cpp

libSeq.so.1.0: Kmer.cpp SeqTool.cpp
	${CC}  ${CFLAGS}  ${LIBS} ${BOOST}  -shared -Wl,-soname,libSeq.so.1 -o libSeq.so.1.0   *.o
	ln -s libSeq.so.1.0 libSeq.so.1
# |
# ===================================================================================================
clean:
	rm *.o
