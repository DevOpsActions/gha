#!/usr/bin/env bash

# Path of the gha on the filesystem
GHA_PATH=$(echo "${GITHUB_CONTEXT:?}" | jq .action_path -r)

# Import colors & functions
source ${GHA_PATH}/utils/colors.bash
source ${GHA_PATH}/utils/check.bash

ACTION=${1:?}

if [[ "${ACTION}" == "commits" ]]; then
    . ${GHA_PATH}/tests/commits.bash
elif [[ "${ACTION}" == "pr_naming" ]]; then
    . ${GHA_PATH}/tests/pr_naming.bash
else
    echo "::error::ERROR: No valid action passed to shellscript"
fi
