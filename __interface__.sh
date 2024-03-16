#!/bin/bash

INTERFACE_PS1="$"

echo -e "\nConnected to FOUNDRY interface via ${AUTH_HOSTNAME}"
echo -e "Ask your query: \n"

# Add this to slow down time between each query
function delayed_echo() {
    local string="$1"
    local delay=0.02

    for (( i = 0; i < ${#string}; i++ )); do
        echo -n "${string:$i:1}"
        sleep $delay
    done
    echo
}

interface_exit_cmd=0
while [[ "${interface_exit_cmd}" != 1 ]]; do
    echo -n "${INTERFACE_PS1} "
    read -r interface_input

    if [ "$interface_input" == '/q' ]; then
        interface_exit_cmd=1
        continue
    fi

    response=$(curl -L -s --header "Content-Type: application/json" --header "Authorization: Bearer ${AUTH_TOKEN}" --request POST --data "{\"query\":\"${interface_input}\"}" --url "${SERVER_URL}/interface/query")
    if [ $(echo $response | jq 'has("error")') == 'true' ]; then
        echo $response | jq -r '.error'
    else
        delayed_echo "$(echo $response | jq -r '.answer')"
    fi
done