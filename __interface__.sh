#!/bin/bash

INTERFACE_PS1="$"
# Add this to slow down time between each query
function delayed_echo() {
    local string="$1"
    local delay=0.02 # 20ms

    for (( i = 0; i < ${#string}; i++ )); do
        echo -n "${string:$i:1}"
        sleep $delay
    done
    echo
}

validate_request --header "Authorization: Bearer ${AUTH_TOKEN}" --request POST --url "${SERVER_URL}/interface/init" || continue
response=$(curl -L -s --header "Authorization: Bearer ${AUTH_TOKEN}" --request POST --url "${SERVER_URL}/interface/init")

INTERFACE_SESSION=$(echo $response | jq -r '.session')
delayed_echo "$(echo $response | jq -r '.welcome')"

interface_exit_cmd=0
while [[ "${interface_exit_cmd}" != 1 ]]; do
    echo -n "${INTERFACE_PS1} "
    read -r interface_input

    response=$(curl -L -s --header "Content-Type: application/json" --header "X-Session: ${INTERFACE_SESSION}" --header "Authorization: Bearer ${AUTH_TOKEN}" --request POST --data "{\"query\":\"${interface_input}\"}" --url "${SERVER_URL}/interface/query")
    if [ $(echo $response | jq 'has("error")') == 'true' ]; then
        echo $response | jq -r '.error'
    elif [ "$(echo "$response" | jq -r '.answer')" == "Session closed" ]; then
        delayed_echo "Session closed"
        interface_exit_cmd=1
        continue
    else
        delayed_echo "$(echo $response | jq -r '.answer')"
    fi
done