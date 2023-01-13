


setup() {
  # get the containing directory of this file
  # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0
  # as those will point to the bats executable's location or
  # the preprocessed file respectively
  DIR=$( cd "$(dirname "$BATS_TEST_FILENAME" )" > /dev/null 2>&1 && pwd)
  # Make executables in DIR visible to PATH
  PATH="$DIR:$PATH"

  # Load bats libraries
  load "$DIR/../test/test_helper/bats-support/load"
  load "$DIR/../test/test_helper/bats-assert/load"
}

@test "can run our script" {
  set +u
  run gitlab.sh --help
  set -u
  assert_output "Welcome to our project"
}
