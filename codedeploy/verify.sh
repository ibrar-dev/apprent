#!/usr/bin/env bash

export TERM="xterm"
sleep 5
sudo /var/app_count/bin/app_count pid
result=$?
if [[ ${result} != 0 ]]; then
    echo "Server NOT running"
    exit 1
else
    echo "Server running"
    exit 0
fi