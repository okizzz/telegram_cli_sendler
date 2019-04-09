#!/usr/bin/env bash

set -ux
set -o pipefail

function search_user(){

    set -o pipefail

    timeout 15 /opt/telegram-cli/telegram-cli \
        --disable-readline \
        --disable-colors \
        --disable-output \
        --profile "${1}" \
        --exec "contact_search ${USRN}" > "${1}.tmp"

        if [ $? -eq 0 ]; then
            SEARCH=$(cat "${1}.tmp")
            sleep 2
            echo "${SEARCH}" | head -n1 | sed 's/ /_/g' > "${1}.tmp" # ошибка сегментации
            echo "${USRN}" Initials found.
            PAUSE=$(shuf -i 360-480 -n 1)
            date +%H:%M:%S\ %d.%m
            echo "Sending after ${PAUSE} seconds"
            echo 0 > "${1}"_counterr.txt
            sleep "${PAUSE}"
            return 0
        else
            return 1
        fi

}

function send_message(){

    set -o pipefail

    TEXT=$(./text_storage.bash)
    RECIPIENT=$(cat ${1}.tmp)

    (echo "contact_search ${USRN}"; sleep 5; echo "msg ${RECIPIENT} ${TEXT}"; sleep 5; echo "safe_quit"; sleep 5) | timeout 20 /opt/telegram-cli/telegram-cli --profile "${1}" --disable-readline --disable-colors --rsa-key server.pub | sed -ne '/<<</p' >> "${1}"_sent.txt

        if [ $? -eq 0 ]; then
            echo "${USRN}" >> "${1}"_sent.txt
            echo "${USRN} Message sent."
            return 0
        else
            return 1
        fi
    
}

function send_verification(){
    
    tail -n 6 "${1}"_sent.txt | grep "<<<"
        if [ $? -eq 0 ]; then
            return 0
        else
            return 1
        fi
}

function change_profile(){
    
    mv profiles.txt profiles_lock.txt
    local EXIT=$?
        if [ ${EXIT} -eq 0 ]; then
            echo "File profile.txt found"
        else
            local COUNT=0
            while [[ ${EXIT} -ne 0 ]] && [[ ${COUNT} -lt 10 ]];
            do
                mv profiles.txt profiles_lock.txt
                local EXIT=$?
                local COUNT=$[COUNT+1]
                sleep 15
            done
        fi
    cat profiles_lock.txt
        if [ $? -eq 0 ]; then
            echo "Available reserve profile"
            NEW_PROFILE=$(head -n1 profiles_lock.txt)
            sed -i '1d' profiles_lock.txt
            sleep 3
            mv profiles_lock.txt profiles.txt
        else
            return 1
        fi
    LASTUSR=$(tail -n5 "${1}"_sent.txt | head -n1)
    grep -A$$ "${LASTUSR}" "${1}.sn" > "${NEW_PROFILE}.sn"
    lxterminal -e proxychains4 -q ./start.bash "${NEW_PROFILE}" &
}

echo "Script started!"

for USRN in $(cat "${1}.sn")
do
    search_user "${1}"
        if [ $? -eq 0 ]; then
            echo "Function search_user exit code 0"
        else
            COUNT=0
            while [ "${COUNT}" -ne 5 ]
                do
                    COUNT=$[COUNT+1]
                    echo $COUNT > "${1}"_counterr.txt
                    search_user "${1}"
                done
        fi
    send_message "${1}"
        EXIT=$?
        COUNTERR=$(cat "${1}"_counterr.txt)
            if [ "${EXIT}" -eq 0 ]; then
                echo "Sending successful. Errors:0"
            elif [ "${EXIT}" -ne 0 ] && [ "${COUNTERR}" -eq 5 ] ; then
                echo "Sending failed. Search initials err :${COUNTERR}"
            elif [ "${EXIT}" -eq 0 ] && [ "${COUNTERR}" -if 0 ] ; then
                echo "Sending successful. Search initials err :${COUNTERR}"
            else
                send_message "${1}"
            fi
    
    send_verification "${1}"
        if [ $? -eq 0 ]; then
            SENT=$(cat "${1}"_sent.txt | grep  "<<<" | wc -l)
            echo "Messages sent ${SENT}"
        else
            change_profile "${1}"
            break
        fi
done

echo "Work done!"

read
read
