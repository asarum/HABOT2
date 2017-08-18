#pragma once

#include <stdint.h>
#include <string>
#include <memory>                       // for shared_ptr<>
#include <deque>
#include <map>
#include <algorithm>                    // for lower_bound()
#include <iostream>

using namespace std;

class SW
{

public:
    // This is the content of matrix: score, pointer
    class Element
    {
    public:
        int score = 0;

        // 0:null, 1:left, 2:up, 3:dignal
        uint8_t  pointer = 0;

        Element(int score=0, uint8_t pointer=0):score(score), pointer(score){}

    };

    typedef vector<vector<Element> > Matrix;

    uint32_t swc(string seq1, string seq2, int MATCH, int MISMATCH, int GAP)
    {
        int len1 = seq1.size();
        int len2 = seq2.size();

        // Initial matrix
        Matrix matrix;
        for(int i=0; i<=len2; i++)
        {
            vector<Element> seq1_element;
            for(int i=0; i<=len1; i++){
                Element element(0, 0);
                seq1_element.push_back(element);
            }
            matrix.push_back(seq1_element);
        }

        // Fill the matrix
        int max_i = 0;
        int max_j = 0;
        int max_s = 0;

        for(int i=1; i<=len2; i++)
        {
            for(int j=1; j<=len1; j++)
            {
                char c1 = seq1[j-1];
                char c2 = seq2[i-1];

                int diagonal, left, up;
                // match score
                if(c1==c2)
                    diagonal = matrix[i-1][j-1].score+MATCH;
                else
                    diagonal = matrix[i-1][j-1].score+MISMATCH;

                // gap score
                up = matrix[i-1][j].score+GAP;
                left = matrix[i][j-1].score+GAP;

                if(diagonal<=0 && up<=0 && left<=0){
                    matrix[i][j].score = 0;
                    matrix[i][j].pointer = 0;
                }

                if(diagonal>=up && diagonal>=left){
                    matrix[i][j].score = diagonal;
                    matrix[i][j].pointer = 3;
                }

                if(up>=diagonal && up>=left){
                    matrix[i][j].score = up;
                    matrix[i][j].pointer = 2;
                }

                if(left>=diagonal && left>=up){
                    matrix[i][j].score = left;
                    matrix[i][j].pointer = 1;
                }

                // set the max score
                if(matrix[i][j].score>max_s){
                    max_i = i;
                    max_j = j;
                    max_s = matrix[i][j].score;
                }
            }
        }

        // Trace back
        string align1 = "";
        string align2 = "";
        int i = max_i;
        int j = max_j;

        int match = 0;
        while (1) {
            if(matrix[i][j].pointer == 0)
                break;

            if(matrix[i][j].pointer == 3){
                align1 += seq1[j-1];
                align2 += seq2[i-1];

                if(seq1[j-1]==seq2[i-1])
                    match++;
                i--;
                j--;
            }

            if(matrix[i][j].pointer == 2){
                align1 += "-";
                align2 += seq2[i-1];
                i--;
            }

            if(matrix[i][j].pointer == 1){
                align1 += seq1[j-1];
                align2 += "-";
                j--;
            }
        }

        reverse(align1.begin(),align1.end());
        reverse(align2.begin(),align2.end());

        // cerr<<align1<<endl;
        // cerr<<align2<<endl;

        return match;
    }

};
