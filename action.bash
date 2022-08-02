#!/usr/bin/env bash

# Path of the gha on the filesystem
GHA_PATH=$(echo "${GITHUB_CONTEXT:?}" | jq .action_path -r)

# Import colors & functions
. ${GHA_PATH}/colors.bash
source ${GHA_PATH}/check.bash

# Extracting Commits API URL from current context
COMMITS_API_URL=$(echo "${GITHUB_CONTEXT:?}" | jq .event.pull_request._links.commits.href -r)

# Check if an error occured during Commits API URL extraction
if [[ "${COMMITS_API_URL:?}" == "null" ]]; then
    echo "::error:Could not determine GitHub Action Context ..."
    exit 1
fi

# Get Commits list
COMMITS=$(curl --request GET                           \
    --header "authorization: Bearer ${GITHUB_TOKEN:?}" \
    --header "content-type: application/json"          \
    --silent                                           \
    --fail                                             \
    ${COMMITS_API_URL} | jq)

# Count them
COMMITS_NB=$(echo "${COMMITS}" | jq '. | length')

echo -e "${IBlue}Found ${UYellow}${COMMITS_NB}${IBlue} commit(s) to check ...${Color_Off}"

i=0
# Iterate over each Commit
for commit in $(echo "${COMMITS}" | jq -r '.[] | @base64'); do
    _jq() {
        echo "${commit}" | base64 --decode | jq -r ${1}
    }

    echo "${commit}" | base64 --decode | jq

    ((i=i+1))

    author=$(_jq '.commit.author.name')
    message=$(_jq '.commit.message')
    sha_long=$(_jq '.parents[0].sha')
    sha_short=${sha_long:0:7}

    check_result=$(check_conventions "${author}" "${message}")

    echo -e " » ${Cyan}${sha_short}${Color_Off} | ${check_result} | ${Green}${author}${Color_Off} | ${Yellow}${message}${Color_Off}"
done
