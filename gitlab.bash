
#!/usr/bin/env bash

function hello_world {
  echo "Welcome to our project"
}

function group_exists() {
# Returns true if the group with the given name exists
# Arguments:
#   Group name
#   Hostname of Gitlab instance
#   Gitlab access token

#  result=$(curl \
#            --silent \
#            --show-error \
#            --request GET \
#            --header "PRIVATE-TOKEN: ${3}" \
#            --header "Content-Type: application/json" \
#            "https://${2}/api/v4/groups?search=${1}" \
#            | jq -j ".[].name" \
#        )
#  echo "$result" "${1}"
#  if [[ "$result" == "${1}" ]]; then
#    return 0
#  else
#    echo "Group ${1} does not exist on ${2}"
#    return 1
#  fi
result="$(get_group_id "${1}" "${2}" "${3}")"
[[ "$result" == "null" ]] && return 1
return 0

}

function get_group_id {
# Retrieves the numeric ID of the group with the given name 
# Arguments:
#   Name of the group (is case sensitive) 
#   Hostname of Gitlab server
#   User token to use for Gitlab authentication
  _err_=0
  result=$(curl \
    --silent \
    --show-error \
    --request GET \
    --header "PRIVATE-TOKEN: ${3}" \
    --header "Content-Type: application/json" \
    "https://${2}/api/v4/groups?search=${1}") \
    || { echo "HTTP request to get group id for group ${1} from ${2} failed" >2 ; _err_=1 ; return 1; }
  
  # Get only group with the given name
  group_ids=$(echo "$result" | jq -j '. | map(select(.name == "'"${1}"'"))' )
  
  # Throw error if there is more than one group with the given name
  group_ids_length=$(echo "$group_ids" | jq -r ". | length")
  [[ "$group_ids_length" -gt 1 ]] && { echo "Found more than one group with the name ${1}" ; _err_=1 ; return 1 ; }

  # Extract id of group
  group_id=$(echo "$group_ids" | jq ".[0].id")
  echo "$group_id" 
}

function create_group {
# Creates a Gitlab group
# Arguments:
#   Name of group (can only contain alphanumeric characters and dashes
#   Hostname of Gitlab server
#   User token to use for Gitlab authentication
# Returns:
#   _group_id: group id of the newly created group
  curl \
    --silent \
    --show-error \
    --request POST \
    --header "PRIVATE-TOKEN: ${3}" \
    --header "Content-Type: application/json" \
    --data "$(printf '{"path": "%s", "name": "%s"}' ${1} ${1})" \
    "https://${2}/api/v4/groups?search=${1}" \
#    || { echo "Failed to create Gitlab group ${1} on ${2}"; exit 1}
}


#function delete_group {
# Deletes a Gitlab group
# Arguments:
#   Name of group (can only contain alphanumeric characters and dashes
#   Hostname of Gitlab server
#   User token to use for Gitlab authentication
#  curl \
#    --silent \
#    --show-error \
#    --request DELETE \
#    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
#    --header "Content-Type: application/json" \
#    --data "$(printf '{"path": "%s", "name": "%s"}' ${1} ${1})" \
#    "https://${GITLAB_HOSTNAME}/api/v4/groups?search=$GROUP_NAME" \
#    || { echo "Failed to create Gitlab group ${1} on ${2}"; exit 1}
#}

