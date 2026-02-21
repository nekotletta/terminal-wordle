#!/bin/bash
echo "Welcome to terminal wordle!"
echo "Guess the word (5 letters)"
echo
date="`date +%Y-%m-%d`";
nyt_api=$( curl -s "https://www.nytimes.com/svc/wordle/v2/$date.json");
word=$(echo "$nyt_api" | jq -r '.solution');

char_arr=()
l=${#word}
for((i=0; i < l; i++)); do
    char_arr+=("${word:i:1}-0")
done


# src: https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
YELLOW="\e[33m";
GREEN="\033[0;32m";
# reset is so that the text goes back to being the default color
RESET="\033[0m";

find_index () {
    local guessed_char=$1
    local guess_idx=$2
    # shift to remove extra arguments from the array
    shift
    shift
    local src_arr=("$@")
    for((i=0; i < 5; i++)); do
        
        IFS='-' read -ra answer_index_info <<< "${src_arr[i]}"
            #characters match                                #can i use it? double letters exist   # did i guess it in the right place?
        if [[ ${answer_index_info[0]} == ${guessed_char} ]] && [[ ${answer_index_info[1]} == 0 ]] && [[ $i == $guess_idx ]]; then
            echo -e "${GREEN}${answer_index_info[0]}${RESET}-${i}"
            return
        elif [[ ${answer_index_info[0]} == ${guessed_char} ]] && [[ ${answer_index_info[1]} == 1 ]]; then
            continue
        elif [[ ${answer_index_info[0]} == ${guessed_char} ]] && [[ ${answer_index_info[1]} == 0 ]] && [[ $i != $guess_idx ]]; then
            echo -e  "${YELLOW}${answer_index_info[0]}${RESET}-${i}"
            return
        fi
    done
    echo ${guessed_char}
}

eval_guess () {
    local word_arr=$1
    res_word=()

    # copy the word array, all characters are usable
    char_arr2=()
    for((i=0; i < 5; i++)); do
        char_arr2+=("${word_arr:i:1}")
    done
    copy=("${char_arr[@]}");

    for((idx=0; idx < 5; idx++)); do
        result=$(find_index "${char_arr2[idx]}" "$idx" "${copy[@]}")
        IFS='-' read -ra index_to_upd <<< "${result}"
        res_word+=$index_to_upd
        # i guessed a character in the word
        if [ ${index_to_upd[1]} ]; then
            # i need to mark this letter, indicating i can't use it again
            save_idx=${index_to_upd[1]}
            save=${copy[$save_idx]}
            fix=${save%?}1
            copy[$save_idx]=$fix
        fi
    done
    echo "-------"
    echo $res_word;
    echo "-------"

}

# check that the user put a valid word
validate_word () {
    local guessed_word=$1
    words=`cat valid-words.txt`
    for w in $words; do
        if [[ $w == $guessed_word ]]; then
            echo 1
            return
        fi
    done
    echo 0
}


attempts=0;
while  [ "$input" != "$word" ] && [ "$attempts" -lt 5 ]; do
    read -e -rn 6 input
    # change to lowercase 
    input=${input,,}
    if [ ${#input} -ne 5 ]; then
        continue
    # guessed in 1 (otherwise it doesnt follow format)
    elif [ ${input} == "$word" ]; then 
        echo "-------"
        echo -e "${GREEN}${input}${RESET}"
        echo "-------"
        break
    else
        is_valid=$(validate_word ${input,,})
        if [[ $is_valid -eq 0 ]]; then
            echo "-------"
            echo "Invalid word. Try again."
            echo "-------"
            continue
        fi
        eval_guess ${input,,}
        ((attempts++))
    fi
    
done
echo
#did i actually win or not
if (("$attempts" < 5)); then
    echo "You have guessed the word!";
else
    echo "The word was $word. Better luck next time!";
fi
