#!/bin/bash

# SERVER_URL="http://foundry-server-navy.vercel.app"
SERVER_URL="localhost:3000"
AUTH_USERNAME=""
AUTH_HOSTNAME=""
AUTH_TOKEN=""

function is_logged () {
    if [ -z "${AUTH_USERNAME}" ] | [ -z "${AUTH_HOSTNAME}" ]; then
        return 1
    else
        return 0
    fi
}

function ps1 () {
    if $(is_logged); then
        echo "[${AUTH_USERNAME}@${AUTH_HOSTNAME}]"
    else
        echo ">"
    fi
}

function help () {
    echo -e "Foundry backdoor client\n"
    echo "help                  Display this message"
    echo "list                  List the available servers"
    echo "login [HOSTNAME]      Login into server (requires username and password)"
    echo "reset-password        Resets the password of a user"
    echo "exit                  Exit utility"
}

function help_auth () {
    echo -e "Foundry server\n"
    echo "help                  Display this message"
    echo "list                  List documents in server"
    echo "open  [DOCUMENT]      Print the document contents"
    echo "exit                  Logout of server"
}

function validate_request () {
    local status_code=$(curl -s -o /dev/null -w "%{http_code}" "$@")
    if [ "$status_code" -ne "200" ]; then
        if [ "$status_code" -eq "000" ]; then
            echo "Error: remote server is unavailable!"
        else
            local response=$(curl -L -s "$@")
            echo -e "\nError: $(echo $response | jq -r '.error')"
        fi
        return 1
    else
        return 0
    fi
}

echo -e "Enter a command or enter help to get a list of commands: \n"

exit_cmd=0
while [[ "${exit_cmd}" != 1 ]]; do
    echo -n "$(ps1) "
    read -r input args

    case $input in
        'help')
            if $(is_logged); then
                help_auth
            else
                help
            fi
            ;;
        'login')
            if $(is_logged); then
                echo "Error: Unknown command $input"
            else
                if [ "$(echo "$args" | awk '{print NF}')" -eq 0 ]; then
                    echo "Error: No arguments provided for $input command"
                    continue
                fi
                hostname=$(echo "$args" | awk '{print $1}')

                # Check server exists
                validate_request --request GET --url "${SERVER_URL}/server/${hostname}" || continue

                # Auth user
                echo -n "username: "
                read -r username
                echo -n "password: "
                read -s password
                echo ""
                validate_request --header "Content-Type: application/json" --request POST --data "{\"username\":\"${username}\",\"password\":\"${password}\"}" --url "${SERVER_URL}/auth" || continue
                
                # Login user to server
                validate_request --header "Content-Type: application/json" --request POST --data "{\"username\":\"${username}\"}" --url "${SERVER_URL}/server/${hostname}/login" || continue
                response=$(curl -L -s --header "Content-Type: application/json" --request POST --data "{\"username\":\"${username}\"}" --url "${SERVER_URL}/server/${hostname}/login")

                AUTH_USERNAME=$username
                AUTH_HOSTNAME=$hostname
                AUTH_TOKEN=$(echo $response | jq -r '.authToken')
                curl -L -s --header "Authorization: Bearer ${AUTH_TOKEN}" --request GET --url "${SERVER_URL}/server/${AUTH_HOSTNAME}/document/motd"

                echo -e "\n\nAccess granted to $hostname"
                echo -e "Enter a command or enter help to get a list of commands: \n"
            fi
            ;;
        'list')
            if $(is_logged); then
                # Fetch documents
                validate_request --header "Authorization: Bearer ${AUTH_TOKEN}" --request GET --url "${SERVER_URL}/server/${AUTH_HOSTNAME}/documents" || continue
                echo $(curl -L -s --header "Authorization: Bearer ${AUTH_TOKEN}" --request GET --url ${SERVER_URL}/server/${AUTH_HOSTNAME}/documents) | jq -r '.documents[]'
            else
                # Fetch servers
                validate_request --request GET --url "${SERVER_URL}/servers" || continue
                echo $(curl -L -s --request GET --url ${SERVER_URL}/servers) | jq -r '.allServers[].hostname'
            fi
            ;;
        'open')
            if $(is_logged); then
                if [ "$(echo "$args" | awk '{print NF}')" -eq 0 ]; then
                    echo "Error: No arguments provided for $input command"
                    continue
                fi
                document_name=$(echo "$args" | awk '{print $1}')

                validate_request --header "Authorization: Bearer ${AUTH_TOKEN}" --request GET --url "${SERVER_URL}/server/${AUTH_HOSTNAME}/document/${document_name}" || continue
                curl -L -s --header "Authorization: Bearer ${AUTH_TOKEN}" --request GET --url "${SERVER_URL}/server/${AUTH_HOSTNAME}/document/${document_name}" | less
            else
                echo "Error: Unknown command $input"
            fi
            ;;
        'reset-password')
            if $(is_logged); then
                echo "Error: Unknown command $input"
            else
                # Auth user
                echo -n "username: "
                read -r username

                response=$(curl -L -s --request POST --url ${SERVER_URL}/user/${username}/forgot-password)
                if [ $(echo $response | jq 'has("result")') == 'true' ]; then
                    echo $response | jq -r '.result'
                else
                    echo $response | jq -r
                fi

                echo -n "reset code: "
                read -r reset_code
                echo -n "new password: "
                read -s password
                echo ""
            fi
            ;;
        'exit')
            if $(is_logged); then
                # Logout
                AUTH_USERNAME=""
                AUTH_HOSTNAME=""
                AUTH_TOKEN=""

                curl -s -o /dev/null --header "Content-Type: application/json" --request POST --data "{\"username\":\"${username}\"}" --url ${SERVER_URL}/server/${hostname}/logout
                echo "Logout"
            else
                exit_cmd=1
            fi
            ;;
        *)
            echo "Error: Unknown command $input"
            ;;
    esac
done