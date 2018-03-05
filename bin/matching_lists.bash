#!/usr/bin/env bash

set -e

match1=/home/srdjanm/Desktop/final1/c_n_+_o\ /with_hetatm/test/table_list_1
match2=/home/srdjanm/Desktop/final1/c_n_+_o\ /with_hetatm/test/pdb_list.txt  

# Create the result file
touch results.txt

while read -r word
do
     if [[ "$word" == $(grep -o "$word" "$match1") ]]; then
             if [[ "$word" != $(grep -o "$word" "results.txt") ]]
             then
                     grep "$(grep "$word" "$match1" | grep -o "[[:digit:]]..$")" "$match1" >> "results.txt"
                     while read -r new
                     do                                 
                             if [[ "$new" =~ $word ]]; then
                                     # Replace the words
                                     sed -i "s/$word/$new/" "results.txt"
                             fi
                     done < <(grep  -o "$word_.*\." "$match2" | sed -e 's/\.//')
                     # Add space between results
                     echo " " >> "results.txt"
             fi
     fi
done < <(cut -d"." -f1 "$match2")

# Remove last blank line from the results file
sed -i '$ d' results.txt
