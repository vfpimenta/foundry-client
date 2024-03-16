#!/bin/bash

# SERVER_URL="https://foundry-server-navy.vercel.app"
SERVER_URL="localhost:3000"
AUTH_USERNAME=""
AUTH_HOSTNAME=""
AUTH_TOKEN=""
PS1=">"

function help () {
    echo -e "Foundry backdoor client\n"
    echo "help                  Display this message"
    echo "list                  List the available servers"
    echo "login [HOSTNAME]      Login into server (requires username and password)"
    echo "reset-password        Resets the password of a user"
    echo "exit                  Exit utility"
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
    echo -n "${PS1} "
    read -r input args

    case $input in
        'help')
            help
            ;;
        'login')
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

            source './__server__.sh'
            ;;
        'list')
            # Fetch servers
            validate_request --request GET --url "${SERVER_URL}/servers" || continue
            echo $(curl -L -s --request GET --url ${SERVER_URL}/servers) | jq -r '["HOSTNAME", "CLERANCE"], (.allServers[] | [.hostname, .level]) | @tsv' | column -t
            ;;
        'reset-password')
            # Auth user
            echo -n "username: "
            read -r username

            response=$(curl -L -s --request POST --url ${SERVER_URL}/user/${username}/forgot-password)
            if [ $(echo $response | jq 'has("result")') == 'true' ]; then
                echo $response | jq -r '.result'
            else
                echo $response | jq -r '.error'
                echo $response | jq -r '.stacktrace'
                echo $response | jq -r '.params.body'
            fi

            echo -n "reset code: "
            read -r reset_code
            echo -n "new password: "
            read -s password
            echo ""

            response=$(curl -L -s --header "Content-Type: application/json" --request POST --data "{\"code\":\"${reset_code}\", \"password\":\"${password}\"}" --url ${SERVER_URL}/user/${username}/reset-password)
            if [ $(echo $response | jq 'has("error")') == 'true' ]; then
                echo $response | jq -r '.error'
            else
                echo "Successfully reset password for ${username}"
            fi
            ;;
        'exit')
            exit_cmd=1
            ;;
        *)
            echo "Error: Unknown command $input"
            help
            ;;
    esac
done