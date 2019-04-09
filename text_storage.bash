#!/usr/bin/env bash

function сhecking_counter(){ 

    COUNT=$(cat text_count.txt)
        local EXIT=$?
        while [[ ${EXIT} -ne 0 ]] && [[ ${COUNT} -lt 50 ]];
            do
                mv text_count.txt text_count_lock.txt
                local EXIT=$?
                local COUNT=$[COUNT+1]
                sleep 15
            done
}

function fresh_text(){        
        
    if [ "${COUNT}" -lt 250 ]; then
        head -n1 text.txt
        local COUNT=$[COUNT+1]
        echo $COUNT > text_count_lock.txt
        mv text_count_lock.txt text_count.txt
    else
        sed -i '1,2d' text.txt
        head -n1 text.txt
        echo "1" > text_count_lock.txt
        mv text_count_lock.txt text_count.txt
    fi
}

сhecking_counter
fresh_text
