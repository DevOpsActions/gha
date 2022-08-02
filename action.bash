#!/usr/bin/env bash

# Path of the gha on the filesystem
GHA_PATH=$(echo "${GITHUB_CONTEXT:?}" | jq .action_path -r)

# Import colors & functions
. ${GHA_PATH}/colors.bash
source ${GHA_PATH}/check.bash

ACTION=${1:?}

if [[ "${ACTION}" == "commits "]]; then
    . ${GHA_PATH}/commits.bash
elif [[ "${ACTION}" == "pr_naming" ]]; then
    . ${GHA_PATH}/pr_naming.bash
else
    echo "::error::ERROR: No valid action passed to shellscript"
fi
