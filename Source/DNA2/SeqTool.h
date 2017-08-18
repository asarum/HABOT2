

#ifndef __SeqTool__
#define __SeqTool__

#include <iostream>
#include "Type.h"
#include "Kmer.h"
#include "SW.h"

/// @brief This class contains tool mainly for alignment and linkage.
///
class SeqTool
{
private:
    Kmer kmer_tool;
    SW sw;

    /// Get the match len by smith waternman model
    ///
    /// @param seq1
    /// @param seq2
    /// @param len the size to divide sequence
    ///
    /// @return the match length
    uint32_t sw_divide(const string &seq1, const string &seq2,
                                int MATCH, int MISMATCH, int GAP);

    /// Get the common k-mer between sequences.
    ///
    /// @param seq1
    /// @param seq2
    /// @param k the size of k-mer
    /// @param jump the jump length to get kmer
    ///
    /// @return the matrix of common kmer
    Matrix getComKmer(const string &seq1,const string &seq2, int k, int jump);

    /// Get the common k-mer between sequences and positions.
    ///
    /// @param seq1
    /// @param seq2
    /// @param k the size of k-mer
    /// @param c1 the first position
    /// @param c2 the second position
    ///
    /// @return the matrix of common kmer
    Matrix getComKmer(const string &seq1, const string &seq2, int k, coord c1, coord c2);

    /// Fill the matrix with consensus k-mer position.
    ///
    /// @param seq1 the input Sequence1
    /// @param seq2 the input Sequence2
    /// @param matrix the matrix to be filled
    /// @param k the size of kmer [5]
    ///
    /// @return the number of new k-mer added to matrix
    void fillMatrix(const string &seq1, const string &seq2, Matrix &matrix, int k=5);

    /// Judge if the two coordinates are linear
    ///
    /// @param c1 the coordinate1
    /// @param c2 the coordinate2
    /// @param error the error rate
    /// @param slope the slope of two coordinates
    ///
    /// @return true if two coordinates are linear
    /// @return false if two coordinates are not linear
    bool isMatch(coord c1, coord c2, float error, float &slope);

public:

    /// Reverse and complement sequence
    ///
    /// @param sequence dna sequence
    /// @return The reverse and completement of sequence
    string revCom(string sequence);

    /// Get the best matrix only contain consensus k-mers
    ///
    /// @param matrix the input matrix contain all k-mers
    /// @param error the error rate
    ///
    /// @return the best matrix
    Matrix bestMatrix(const Matrix &matrix, float error=0.1);

    /// Align sequences via the matrix
    ///
    /// @param seq_1 the sequence 1
    /// @param seq_2 the sequence 2
    /// @param matrix the matrix contain anchors
    /// @param mode the align mode[1]. 1:pacbio, 2:corrected
    ///
    /// @return the alignment result
    Conn_info detail(const string &seq_1,const string &seq_2, Matrix& matrix, int mode=1);

    /// Align between two sequences
    ///
    /// @param seq_1 the sequence 1
    /// @param seq_2 the sequence 2
    /// @param mode the alignment mode[1].
    /// 1: uncorrected reads. 2: corrected.
    ///
    /// @return the alignment result
    Conn_info alignment(string seq_1, string seq_2, int mode=1);

    /// Align between two sequences
    ///
    /// @param seq_1 the sequence 1
    /// @param seq_2 the sequence 2
    /// @param the matrix
    ///
    /// @return the alignment result
    Conn_info align_kmer(string seq_1, string seq_2, Matrix &matrix);
};

#endif /* defined(__SeqTool__) */
