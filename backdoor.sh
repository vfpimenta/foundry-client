#!/bin/bash

# SERVER_URL="http://foundry-server-navy.vercel.app"
SERVER_URL="localhost:3000"
AUTH_USERNAME=""
AUTH_HOSTNAME=""

function ps1 () {
    if [ -z "${AUTH_USERNAME}" ] | [ -z "${AUTH_HOSTNAME}" ]; then
        echo ">"
    else
        echo "[${AUTH_USERNAME}@${AUTH_HOSTNAME}]"
    fi
}

function header () {
    echo "###############################################"
    echo "#  _____ _____ _____ _____ ____  _____ __ __  #"
    echo "# |   __|     |  |  |   | |    \| __  |  |  | #"
    echo "# |   __|  |  |  |  | | | |  |  |    -|_   _| #"
    echo "# |__|  |_____|_____|_|___|____/|__|__| |_|   #"
    echo "#                                             #"
    echo "###############################################"
    echo -e "\n"
    echo "You are entering into a secured area! Your IP, Login Time, Username has been noted and has been sent to the server administrator!"
    echo "This service is restricted to authorized users only. All activities on this system are logged."
    echo -e "Unauthorized access will be fully investigated and reported to the appropriate law enforcement agencies.\n\n"
}

echo -e "Enter a command: \n"

exit_cmd=0
while [[ "${exit_cmd}" != 1 ]]; do
    echo -n "$(ps1) "
    read -r input args

    case $input in
        'help')
            echo "No help"
            ;;
        'login')
            if [ "$(echo "$args" | awk '{print NF}')" -eq 0 ]; then
                echo "Error: No arguments provided for login command"
                continue
            fi
            hostname=$(echo "$args" | awk '{print $1}')

            # Check server exists
            status_code=$(curl -s -o /dev/null -w "%{http_code}" --request GET --url "${SERVER_URL}/server/${hostname}")
            response=$(curl -L -s --request GET --url ${SERVER_URL}/server/${hostname})
            if [ "$status_code" -ne "200" ]; then
                echo "Error $response"
                continue
            fi

            # Auth user
            echo -n "username: "
            read -r username
            echo -n "password: "
            read -s password
            echo ""
            status_code=$(curl -s -o /dev/null -w "%{http_code}" --header "Content-Type: application/json" --request POST --data "{\"username\":\"${username}\",\"password\":\"${password}\"}" --url "${SERVER_URL}/auth")
            response=$(curl -L -s --header "Content-Type: application/json" --request POST --data "{\"username\":\"${username}\",\"password\":\"${password}\"}" --url "${SERVER_URL}/auth")
            if [ "$status_code" -ne "200" ]; then
                echo -e "\nError $response"
                continue
            fi
            
            # Login user to server
            status_code=$(curl -s -o /dev/null -w "%{http_code}" --header "Content-Type: application/json" --request POST --data "{\"username\":\"${username}\"}" --url "${SERVER_URL}/server/${hostname}/login")
            response=$(curl -L -s --header "Content-Type: application/json" --request POST --data "{\"username\":\"${username}\"}" --url ${SERVER_URL}/server/${hostname}/login)
            if [ "$status_code" -ne "200" ]; then
                echo -e "\nError $response"
                continue
            fi

            AUTH_USERNAME=$username
            AUTH_HOSTNAME=$hostname
            header

            echo -e "Logged in $hostname \n"
            ;;
        'exit')
            if [ -z "${AUTH_USERNAME}" ] | [ -z "${AUTH_HOSTNAME}" ]; then
                exit_cmd=1
            else
                # Logout
                AUTH_USERNAME=""
                AUTH_HOSTNAME=""
                echo "Logout"
            fi
            ;;
        *)
            echo "Error: Unknown command $input"
            ;;
    esac
done