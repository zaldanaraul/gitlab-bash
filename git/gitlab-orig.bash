#!/bin/bash
#
# Copyright (c) 2021 Expeto Wireless.
#
#  All Rights Reserved.
#
# NOTICE:  All information contained herein is, and remains
# the property of the respective contributors and their suppliers,
# if any.  The intellectual and technical concepts contained
# herein are proprietary to the contributors and their suppliers and may
# be covered by U.S., Canadian and other Patents, patents in process,
# and are protected by trade secret or copyright law.
#
# See LICENSE file for licensing information and a full MIT license under which
# this code is distributed.
#
# Version
version='0.1'
echo "${BASH_VERSINFO[@]}"

# TODO
# Extract project, group and namespace lookups into their own functions
# Write deletion functions and unit tests that use create/delete

# Example tests
# token="MY_ACCESS_TOkEN"
# create_gitlab_group stuff gitlab.expeto.io "${token}"
# create_gitlab_group_deployment_token stuffy stuff gitlab.expeto.io "${token}"
# create_gitlab_project stuffp stuffp gitlab.expeto.io "${token}"
# create_gitlab_project_api_token stuffs stuff gitlab.expeto.io "${token}"
# create_gitlab_project_variable stuffa stuffval stuffp gitlab.expeto.io "${token}"

# Source shtdlib
source "$(dirname "${BASH_SOURCE[0]}")/../import_example.sh"

# Store a list of functions before processing this file
readarray -t functions_before < <( declare -F )

#######################################
# Creates a Gitlab project in a specific group
# Arguments:
#   Name project, must only contain alphanumeric characters and dashes
#   Name or ID of the group
#   Hostname of Gitlab server
#   User token to use for Gitlab authentication
#######################################
function create_gitlab_project {
    color_echo green "Creating Gitlab project: ${1}"
    if [[ ${2} == ?(-)+([0-9]) ]] ; then # If the project isn't an integer look ip it's ID
        namespace_id="${2}"
    else
        response="$(curl --header "PRIVATE-TOKEN: ${4}" "https://${3}/api/v4/namespaces?search=${2}")"
        namespace_id="$( echo "${response}" | jq '.[] | select (.path == "'${2}'") | .id' || exit_on_fail "Failed to process response to Namespace lookup $(echo "${response}" | jq . )")"
    fi

    curl --silent --show-error --request POST --header "PRIVATE-TOKEN: ${4}" \
        "https://${3}/api/v4/projects?name=${1}&namespace_id=${namespace_id}" || \
        exit_on_fail "Failed to create Gitlab project/repository ${1}, exiting!"
}

#######################################
# Creates a Gitlab group
# Arguments:
#   Name of group, must only contain alphanumeric characters and dashes
#   Hostname of Gitlab server
#   User token to use for Gitlab authentication
#######################################
function create_gitlab_group {
    color_echo green "Creating Gitlab group: ${1}"
    curl --silent --show-error --request POST --header "PRIVATE-TOKEN: ${3}" \
     --header "Content-Type: application/json" \
     --data '{"path": "'${1}'", "name": "'${1}'"}' \
     "https://${2}/api/v4/groups/" || \
     exit_on_fail "Failed to create Gitlab Group ${1}, exiting!"
}

#######################################
# Creates a Gitlab group wide deployment key and exports an environment variable
# called GITLAB_DEPLOYMENT_TOKEN with the token value.
# Arguments:
#   Name of key, must only contain alphanumeric characters and dashes
#   Name or ID of the group
#   Hostname of Gitlab server
#   User token to use for Gitlab authentication
#   Expiration date, defaults to 10 years
#######################################
function create_gitlab_group_deployment_token {
    color_echo green "Creating Gitlab group deployment token: ${1} for group ${2}"
    if [[ ${2} == ?(-)+([0-9]) ]] ; then # If the group isn't an integer look ip it's ID
        group_id="${2}"
    else
        response="$(curl --silent --show-error --header "PRIVATE-TOKEN: ${4}" "https://${3}/api/v4/groups?search=${2}")"
        group_id="$(echo "${response}" | jq '.[] | select (.path == "'${2}'") | .id' || exit_on_fail "Failed to process response to Group lookup $(echo "${response}" | jq . )")"
    fi
    token_expiration_date="${5:-${TOKEN_EXPIRATION_DATE:-$(date +%F --date="+3650 days")}}" # Default token lifetime is 10 years
    export GITLAB_DEPLOYMENT_TOKEN="$(curl --silent --show-error --request POST --header "PRIVATE-TOKEN: ${4}" --header "Content-Type: application/json" \
        --data '{"name": "'${1}'", "expires_at": "'${token_expiration_date}'", "username": "'${1}'", "scopes": ["read_repository"]}' \
        "https://${3}/api/v4/groups/${group_id}/deploy_tokens/" | jq --raw-output ' .token ' || exit_on_fail "Failed to create Gitlab deployment token ${1} in group ${2}, exiting!")"
    echo "${GITLAB_DEPLOYMENT_TOKEN}"
}

#######################################
# Creates a Gitlab project API key and exports an environment variable called
# GITLAB_API_TOKEN with the token value.
# Arguments:
#   Name of key, must only contain alphanumeric characters and dashes
#   Name or ID of the project
#   Hostname of Gitlab server
#   User token to use for Gitlab authentication
#   Expiration date, defaults to 10 years
#######################################
function create_gitlab_project_api_token {
    color_echo green "Creating Gitlab project api token: ${1} for project ${2}"
    if [[ ${2} == ?(-)+([0-9]) ]] ; then # If the project isn't an integer look ip it's ID
        project_id="${2}"
    else
        response="$(curl --silent --show-error --header "PRIVATE-TOKEN: ${4}" "https://${3}/api/v4/projects?search=${2}")"
        project_id="$( echo "${response}" | jq '.[] | select (.path == "'${2}'") | .id' || exit_on_fail "Failed to process response to Project lookup $(echo "${response}" | jq . )")"
    fi
    token_expiration_date="${5:-${TOKEN_EXPIRATION_DATE:-$(date +%F --date="+3650 days")}}" # Default token lifetime is 10 years
    export GITLAB_API_TOKEN="$(curl --silent --show-error --request POST --header "PRIVATE-TOKEN: ${4}" \
        --header "Content-Type:application/json" \
        --data '{ "name":"'${1}'", "scopes":["api", "read_api"], "expires_at":"'${token_expiration_date}'", "access_level": 40 }' \
        "https://${3}/api/v4/projects/${project_id}/access_tokens" | jq --raw-output ' .token ' || exit_on_fail "Failed to create Gitlab API token ${1} in project ${2}, exiting!")"
    echo "${GITLAB_API_TOKEN}"
}

#######################################
# Creates a Gitlab CI/CD variable and sets it's value
# Arguments:
#   Key/Name of the variable
#   Value of variabe
#   Name or ID of the project to create the variable in
#   Hostname of Gitlab server
#   User token to use for Gitlab authentication
#######################################
function create_gitlab_project_variable {
    color_echo green "Creating Gitlab project variable: ${1} for project ${3}"
    if [[ ${3} == ?(-)+([0-9]) ]] ; then # If the project isn't an integer look ip it's ID
        project_id="${3}"
    else
        response="$(curl --silent --show-error --header "PRIVATE-TOKEN: ${5}" "https://${4}/api/v4/projects?search=${3}")"
        project_id="$( echo "${response}" | jq '.[] | select (.path == "'${3}'") | .id' || exit_on_fail "Failed to process response to Project lookup $(echo "${response}" | jq . )")"
    fi

    curl --silent --show-error --request POST --header "PRIVATE-TOKEN: ${5}" \
    "https://${4}/api/v4/projects/${project_id}/variables" --form "key=${1}" --form "value=${2}" || \
     exit_on_fail "Failed to create Gitlab project variable ${1} in project ${3}, exiting!"
}

#######################################
# Registers a Kubernetes agent with a Gitlab project
# Arguments:
#   Name of the agent
#   Name or ID of the project to register the agent with
#   Hostname of Gitlab server
#   User token to use for Gitlab authentication
#######################################
function register_k8s_agent {
    color_echo green "Registering Giblab k8s agent with project ${2}"
    if [[ ${2} == ?(-)+([0-9]) ]] ; then # If the project isn't an integer look ip it's ID
        project_id="${2}"
    else
        response="$(curl --silent --show-error --header "PRIVATE-TOKEN: ${4}" "https://${3}/api/v4/projects?search=${2}")"
        project_id="$( echo "${response}" | jq '.[] | select (.path == "'${2}'") | .id' || exit_on_fail "Failed to process response to Project lookup $(echo "${response}" | jq . )")"
    fi

     curl --silent --show-error --request POST --header "PRIVATE-TOKEN: ${4}" \
    "https://${3}/api/v4/projects/${project_id}/cluster_agents" \
    -H "Content-Type:application/json" \
    -X POST --data '{"name":"'"${1}"'"}'
}

# Store a list of functions after processing this file and the delta from
# before processing the file, then read comments as documentation
readarray -t functions_after < <( declare -F )
readarray -t functions_delta < <( echo "${functions_before[@]}" "${functions_after[@]}" | tr ' ' '\n' | sort | uniq -u )
declare -a function_description
for func in "${functions_delta[@]}" ; do
    function_description+=("$(sed -n '/##*#/{:start /function /!{N;b start};/'"${func}"'/p}' "${BASH_SOURCE[0]}" | grep -v '^function ' | grep -v '^#*$' | head -n 1 | sed 's/^#//')")
done


# This is a sample print usage function, it should be overwritten by scripts
# which import this library
function print_usage {
cat << EOF
usage: ${0} subcommand
Subcommands:
$(for (( i=0; i<${#functions_delta[@]}; i++ )); do
  printf "%-40s %-80s\n" "${functions_delta[i]}" "${function_description[i]}"
done)
For more detail on each subcommand just call it with --help
Version: ${version:-${shtdlib_version}}
EOF
}

# If script is bein executed rather than sourced we try to find a function
# matching the name of the first argument, all subsequent arguments will be
# passed on as arguments to that function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    debug 9 "Script ${BASH_SOURCE[0]} was executed"
    # Implement subcommand help
    if [ "${2}" == '--help' ] ; then
        printf '# %s - %s #\n' "${0}" "${1}"
        sed -n '/##*#/{:start /function /!{N;b start};/'"${1}"' /p}' "${BASH_SOURCE[0]}" | grep -v '^function '
        exit 1
    fi

    # If there are more than 2 arguments and if the second argument matches a
    # function defined in this file then call it
    if [[ "${#:-0}" -ge 2 ]] && in_array "${1}" ${functions_delta[@]} ; then
        debug 9 "Running command ${*}"
        debug 10 "BASH_SOURCE: ${BASH_SOURCE[*]}"
        debug 10 "BASH_LINENO: ${BASH_LINENO[*]}"
        debug 10 "FUNCNAME: ${FUNCNAME[*]}"

        "${@}"
    else
        print_usage
        exit 1
    fi
fi
