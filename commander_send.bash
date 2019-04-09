#!/usr/bin/env bash

set -ux
set -o pipefail

function copy_username(){

head -n25 sends.txt > "${1}".sn

}

function start_thread(){

lxterminal -e proxychains4 -q ./start.bash "${1}" &

}

function cut_username(){

sed -i '1,25d' sends.txt
sleep 60

}

for PROFILE in $(cat "profiles.list")
do

copy_username "${PROFILE}"

start_thread "${PROFILE}"

cut_username 

done
