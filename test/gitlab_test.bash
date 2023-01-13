
function skip_if_undefined {
  # Skips execution of the test or setup function it's called from
  # if the given environment variable is not defined
  local -n ENV_VAR="${1}"
  if [[ -z "$ENV_VAR" ]]; then
    skip "${1} is not defined"
  fi
}

setup() {
  # get the containing directory of this file
  # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0
  # as those will point to the bats executable's location or
  # the preprocessed file respectively
  DIR=$( cd "$(dirname "$BATS_TEST_FILENAME" )" > /dev/null 2>&1 && pwd)
  # Make executables in project's root visible to PATH
  PATH="$DIR/..:$PATH"

  # Load bats libraries
  load "$DIR/test_helper/bats-support/load"
  load "$DIR/test_helper/bats-assert/load"
  source gitlab.bash
  
  skip_if_undefined "EXISTING_GROUP_NAME"
  skip_if_undefined "EXISTING_GROUP_ID"
  skip_if_undefined "GITLAB_TOKEN"
  skip_if_undefined "GITLAB_HOSTNAME"
}

@test "get_group_id returns the group id of the group with the given path" {
    run get_group_id "$EXISTING_GROUP_NAME" "$GITLAB_HOSTNAME" "$GITLAB_TOKEN"
    assert_output "$EXISTING_GROUP_ID"
}

@test "group_exists returns 0 if the given group exists" {
  # skip this test if existing_group_name environment variable is not defined
  group_exists "$EXISTING_GROUP_NAME"  "$GITLAB_HOSTNAME" "$GITLAB_TOKEN"
}

@test "group_exists returns 1 if the given group does not exist" {
  # skip this test if existing_group_name environment variable is not defined
  ! group_exists "this_group_cannot_exist"  "$GITLAB_HOSTNAME" "$GITLAB_TOKEN"
}


@test "create_group creates a gitlab group with a given name" {
  skip "Skipping for Dev"
  # Generate group name
  local GROUP_NAME=$(echo $RANDOM | md5sum | head -c 20)

  # Create group on Gitlab
  create_group "$GROUP_NAME" "$GITLAB_HOSTNAME" "$GITLAB_TOKEN"

  # Make sure group exists on Gitlab instance
  group_exists "$GROUP_NAME" "$GITLAB_HOSTNAME" "$GITLAB_TOKEN"
}

@test "create_group returns the group id of the newly created group" {
  skip "Skipping for Dev"
  # Generate group name
  local GROUP_NAME=$(echo $RANDOM | md5sum | head -c 20)

  # Create group on Gitlab
  create_group "$GROUP_NAME" "$GITLAB_HOSTNAME" "$GITLAB_TOKEN"

  # Make sure group exists on Gitlab instance
  group_exists "$GROUP_NAME" "$GITLAB_HOSTNAME" "$GITLAB_TOKEN"
}

@test "delete_group deletes a gitlab group with a given name" {
  skip "Skipping for Dev"
  # Generate group name
  local GROUP_NAME=$(echo $RANDOM | md5sum | head -c 20)

  # Create group on Gitlab
  create_group "$GROUP_NAME" "$GITLAB_HOSTNAME" "$GITLAB_TOKEN"

  # Make sure group exists on Gitlab instance
  group_exists "$GROUP_NAME" "$GITLAB_HOSTNAME" "$GITLAB_TOKEN"

  # Delete group
  delete_group "$GROUP_NAME" "$GITLAB_HOSTNAME" "$GITLAB_TOKEN" 

  # Make sure group does not exist on Gitlab instance
  ! group_exists "$GROUP_NAME" "$GITLAB_HOSTNAME" "$GITLAB_TOKEN"
}
