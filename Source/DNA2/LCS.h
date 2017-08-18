#include <stdint.h>
#include <string>
#include <memory>                       // for shared_ptr<>
#include <deque>
#include <map>
#include <algorithm>                    // for lower_bound()
#include <iostream>

using namespace std;

class LCS {
protected:
  // This linked list class is used to trace the LCS candidates

  class Pair
  {
  public:
    uint32_t index1;
    uint32_t index2;
    shared_ptr<Pair> next;

    Pair(uint32_t index1, uint32_t index2, shared_ptr<Pair> next = nullptr)
      : index1(index1), index2(index2), next(next) {
    }

    static shared_ptr<Pair> Reverse(const shared_ptr<Pair> pairs) {
      shared_ptr<Pair> head = nullptr;
      for (auto next = pairs; next != nullptr; next = next->next)
        head = make_shared<Pair>(next->index1, next->index2, head);
      return head;
    }
  };

  typedef deque<shared_ptr<Pair>> PAIRS;
  typedef deque<uint32_t> THRESHOLD;
  typedef deque<uint32_t> INDEXES;
  typedef map<char, INDEXES> CHAR2INDEXES;
  typedef deque<INDEXES*> MATCHES;

  // return the LCS as a linked list of matched index pairs
  uint64_t Pairs(MATCHES& matches, shared_ptr<Pair> *pairs) {
    auto trace = pairs != nullptr;
    PAIRS traces;
    THRESHOLD threshold;

    //
    //[Assert]After each index1 iteration threshold[index3] is the least index2
    // such that the LCS of s1[0:index1] and s2[0:index2] has length index3 + 1
    //
    uint32_t index1 = 0;
    for (const auto& it1 : matches) {
      if (!it1->empty()) {
        auto dq2 = *it1;
        auto limit = threshold.end();
        for (auto it2 = dq2.begin(); it2 != dq2.end(); it2++)
        {
          // Each of the index1, index2 pairs considered here correspond to a match
          auto index2 = *it2;
          // if(abs(index2-index1)>30) continue;
          //
          // Note: The index2 values are monotonically decreasing, which allows the
          // thresholds to be updated in place.  Montonicity allows a binary search,
          // implemented here by std::lower_bound()
          //
          limit = lower_bound(threshold.begin(), limit, index2);
          auto index3 = distance(threshold.begin(), limit);

          //
          // Look ahead to the next index2 value to optimize space used in the Hunt
          // and Szymanski algorithm.  If the next index2 is also an improvement on
          // the value currently held in threshold[index3], a new Pair will only be
          // superseded on the next index2 iteration.
          //
          // Depending on match redundancy, the number of Pair constructions may be
          // divided by factors ranging from 2 up to 10 or more.
          //
          auto skip = it2 + 1 != dq2.end() &&
            (limit == threshold.begin() || *(limit - 1) < *(it2 + 1));

          if (skip) continue;

          if (limit == threshold.end()) {
            // insert case
            threshold.push_back(index2);
            if (trace) {
              auto prefix = index3 > 0 ? traces[index3 - 1] : nullptr;
              auto last = make_shared<Pair>(index1, index2, prefix);
              traces.push_back(last);
            }
          }
          else if (index2 < *limit) {
            // replacement case
            *limit = index2;
            if (trace) {
              auto prefix = index3 > 0 ? traces[index3 - 1] : nullptr;
              auto last = make_shared<Pair>(index1, index2, prefix);
              traces[index3] = last;
            }
          }
        }                                 // next index2
      }

      index1++;
    }                                     // next index1

    if (trace) {
      auto last = traces.size() > 0 ? traces.back() : nullptr;
      // Reverse longest back-trace
      *pairs = Pair::Reverse(last);
    }

    auto length = threshold.size();
    return length;
  }

  //
  // Match() avoids incurring m*n comparisons by using the associative
  // memory implemented by CHAR2INDEXES to achieve O(m+n) performance,
  // where m and n are the input lengths.
  //
  // The lookup time can be assumed constant in the case of characters.
  // The symbol space is larger in the case of records; but the lookup
  // time will be O(log(m+n)), at most.
  //
  void Match(CHAR2INDEXES& indexes, MATCHES& matches,
    const string& s1, const string& s2) {
    uint32_t index = 0;
    for (const auto& it : s2){
      indexes[it].push_front(index++);
    }

    for (const auto& it : s1) {
      auto& dq2 = indexes[it];
      matches.push_back(&dq2);
    }
  }

  string Select(shared_ptr<Pair> pairs, uint64_t length,
    bool right, const string& s1, const string& s2, int& ins, int &del, int& mis) {
    string buffer;
    buffer.reserve(length);
    ins = 0;
    del = 0;
    mis = 0;
    int pre_index1 = -1;
    int pre_index2 = -1;
    for (auto next = pairs; next != nullptr; next = next->next) {
      auto c = right ? s2[next->index2] : s1[next->index1];
      buffer.push_back(c);
      int index1 = next->index1;
      int index2 = next->index2;
      if(pre_index1!=-1){
        int gap1 = index1-pre_index1;
        int gap2 = index2-pre_index2;

        if(gap1==gap2)
          mis += gap1-1;
        if(gap1==1){
          int num = 0;
          string temp2 = s2.substr(pre_index2,gap2+1);
          for(int i=1;i<temp2.size()-1;i++){
            if(temp2[i]!=temp2[i-1] && temp2[i]!=temp2[i+1])
              num++;
          }
          del += num++;
        }else{
          int num = 0;
          string temp1 = s1.substr(pre_index1,gap1+1);
          for(int i=1;i<temp1.size()-1;i++){
            if(temp1[i]!=temp1[i-1] && temp1[i]!=temp1[i+1])
              num++;
          }
          ins += num;
        }

        // if(gap1!=gap2){
        //   string temp1 = s1.substr(pre_index1,gap1+1);
        //   string temp2 = s2.substr(pre_index2,gap2+1);
        //   cerr<<temp1<<" "<<s1[index1]<<" "<<temp2<<" "<<s2[index2]<<endl;
        // }
      }
      pre_index1 = index1;
      pre_index2 = index2;
    }
    return buffer;
  }

  bool isDup(const string& str)
  {
      if(str.size()==2) return true;

      int mid = str.size()-2;
      int las = str.size()-1;

      int match = 0;
      for(int i=1; i<las; i++)
          if(str[0]==str[i]) match++;
      if(match==mid) return true;

      match = 0;
      for(int i=1; i<las; i++)
          if(str[las]==str[i]) match++;
      if(match==mid) return true;

      return false;
  }

public:
  string Correspondence(const string& s1, const string& s2, int& ins, int &del, int& mis) {
    CHAR2INDEXES indexes;
    MATCHES matches;                    // holds references into indexes
    Match(indexes, matches, s1, s2);
    shared_ptr<Pair> pairs;             // obtain the LCS as index pairs
    auto length = Pairs(matches, &pairs);
    return Select(pairs, length, false, s1, s2,
                  ins, del, mis);
  }

  uint32_t GetSimi(const string& s1, const string& s2, int& ins, int &del, int& mis)
  {
      CHAR2INDEXES indexes;
      MATCHES matches;                    // holds references into indexes
      Match(indexes, matches, s1, s2);
      shared_ptr<Pair> pairs;             // obtain the LCS as index pairs
      auto length = Pairs(matches, &pairs);

      ins=del=mis=0;
      shared_ptr<Pair> pre_pair = nullptr;
      for (auto next = pairs; next != nullptr; next = next->next)
      {
          if(pre_pair!=nullptr)
          {
              int gap1 = next->index1-pre_pair->index1;
              int gap2 = next->index2-pre_pair->index2;
              string str1 = s1.substr(pre_pair->index1, gap1+1);
              string str2 = s2.substr(pre_pair->index2, gap2+1);

              if(gap1==gap2 && gap1>1) mis += gap1-1;
              if(gap1>gap2) ins += gap1-gap2;
              if(gap2>gap1) del += gap2-gap1;
          }
          pre_pair = next;
     }
     return length;
  }

};
