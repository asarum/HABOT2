# export
export PGDATA=/var/postgresql/data
# boost
export BOOST_LIB="/nfs/config/boost/lib"
export BOOST_INCLUDE="/nfs/config/boost/include"
# gcc
export GCC_LIB="/nfs2/config/gcc/gcc-4.9.2/lib/:/nfs2/config/gcc/gcc-4.9.2/lib64/"
export GXX="/nfs2/config/gcc/gcc-4.9.2/bin"
export CPLUS_INCLUDE_PATH="$BOOST_INCLUDE"
export MPC="/nfs2/lib/mpc-0.8.1/lib/"
export LIBPBDATA_LIB="/lustre/project/og03/Public/Pipe/DNA_DENOVO/PacBio/pbdagcon/blasr_libcpp/pbdata"
export LIB_SEQ="/lustre/project/og03/Public/Git/Denovo_pipe/TheThinker3/Source/DNA2"

# DALIGN
export DALIGN="/lustre/project/og03/Public/Pipe/DNA_DENOVO/PacBio/pbdagcon/DALIGNER";
export DAZDB="/lustre/project/og03/Public/Pipe/DNA_DENOVO/PacBio/pbdagcon/DAZZ_DB";
export FACLON="/lustre/project/og03/Public/Pipe/DNA_DENOVO/PacBio/pbdagcon/src/cpp";

# libarary
export LIB_BLASR="/lustre/project/og03/Public/Pipe/DNA_DENOVO/PacBio/pbdagcon/blasr_libcpp/alignment"
export LD_LIBRARY_PATH="$LIB_SEQ:$LIB_BLASR:$LIBPBDATA_LIB:$GCC_LIB:$BOOST_LIB:$MPC:$LD_LIBRARY_PATH"
export PATH="$FACLON:$DALIGN:$DAZDB:$GXX:$BOOST_INCLUDE:/nfs/config/perl-5.18.4/perl:$PATH"
# proovread
export PROOVREAD=/lustre/project/og03/Public/Pipe/DNA_DENOVO/PacBio/Proovread/Source/proovread/bin/
export PATH=/lustre/project/og03/Public/Pipe/Software/PERL/perl_5.18.4/bin:$PROOVREAD:$PATH
export PATH=/lustre/project/og05/liuxiayang/samtools-1.3/bin:/nfs/biosoft/bin:$PATH

#source /nfs2/pipe/genomics/DNA_DENOVO/PacBio/smrtanalysis/current/etc/setup.sh
