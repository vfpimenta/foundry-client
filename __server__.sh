#!/bin/bash

SERVER_PS1="[${AUTH_USERNAME}@${AUTH_HOSTNAME}]"

function server_help () {
    echo -e "Foundry server\n"
    echo "help                  Display this message"
    echo "status                Display the server status information"
    echo "list                  List documents in server"
    echo "open  [DOCUMENT]      Print the document contents"
    echo "interface             Initiate the interface utility"
    echo "exit                  Logout of server"
}

function print_status () {
    hostname=$1
    response=$2
    echo "Hostname: ${hostname}"
    echo "-----------------------"
    echo "OS: $(echo $response | jq -r '.os')"
    echo "Kernel: $(echo $response | jq -r '.kernel')"
    echo "Uptime: $(echo $response | jq -r '.uptime')"
    echo "Packages: $(echo $response | jq '.packages')"
    echo "Shell: $(echo $response | jq -r '.shell')"
    echo "CPU: $(echo $response | jq -r '.cpu')"
    echo "Memory: $(echo $response | jq -r '.memory')"
    echo "Disk: $(echo $response | jq -r '.disk')"
    echo "Users: $(echo $response | jq '.users')"
}

curl -L -s --header "Authorization: Bearer ${AUTH_TOKEN}" --request GET --url "${SERVER_URL}/server/${AUTH_HOSTNAME}/document/motd"

echo -e "\n\nAccess granted to $hostname"
response=$(curl -L -s --request GET --url "${SERVER_URL}/user/${AUTH_USERNAME}/messages")
if [ $(echo $response | jq 'has("total_messages")') == 'true' ]; then
    unread_messages=$(echo $response | jq -r '.total_messages')
    echo -e "*** YOU HAVE ${unread_messages} UNREAD MESSAGE(S) ***"
fi
echo -e "Enter a command or enter help to get a list of commands: \n"

server_exit_cmd=0
while [[ "${server_exit_cmd}" != 1 ]]; do
    echo -n "${SERVER_PS1} "
    read -r server_input server_args

    case $server_input in
        'help')
            server_help
            ;;
        'status')
            validate_request --header "Authorization: Bearer ${AUTH_TOKEN}" --request GET --url "${SERVER_URL}/server/${AUTH_HOSTNAME}/status" || continue
            print_status $AUTH_HOSTNAME "$(curl -L -s --header "Authorization: Bearer ${AUTH_TOKEN}" --request GET --url ${SERVER_URL}/server/${AUTH_HOSTNAME}/status)"
            ;;
        'list')
            # Fetch documents
            validate_request --header "Authorization: Bearer ${AUTH_TOKEN}" --request GET --url "${SERVER_URL}/server/${AUTH_HOSTNAME}/documents" || continue
            echo $(curl -L -s --header "Authorization: Bearer ${AUTH_TOKEN}" --request GET --url ${SERVER_URL}/server/${AUTH_HOSTNAME}/documents) | jq -r '.documents[]'
            ;;
        'open')
            if [ "$(echo "$server_args" | awk '{print NF}')" -eq 0 ]; then
                echo "Error: No arguments provided for $server_input command"
                continue
            fi
            document_name=$(echo "$server_args" | awk '{print $1}')

            validate_request --header "Authorization: Bearer ${AUTH_TOKEN}" --request GET --url "${SERVER_URL}/server/${AUTH_HOSTNAME}/document/${document_name}" || continue
            curl -L -s --header "Authorization: Bearer ${AUTH_TOKEN}" --request GET --url "${SERVER_URL}/server/${AUTH_HOSTNAME}/document/${document_name}" | less
            ;;
        'interface')
            source './__interface__.sh'
            ;;
        'exit')
            # Logout
            AUTH_USERNAME=""
            AUTH_HOSTNAME=""
            AUTH_TOKEN=""

            curl -s -o /dev/null --header "Content-Type: application/json" --request POST --data "{\"username\":\"${username}\"}" --url ${SERVER_URL}/server/${hostname}/logout
            echo "Logout"
            server_exit_cmd=1
            ;;
        *)
            echo "Error: Unknown command $server_input"
            server_help
            ;;
    esac
done