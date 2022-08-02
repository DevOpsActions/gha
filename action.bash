#!/usr/bin/env bash

GHA_PATH=$(echo "${GITHUB_CONTEXT:?}" | jq .action_path -r)

# Import colors
. ${GHA_PATH}/colors.bash

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

echo -e "${Yellow}Found ${Cyan}${COMMITS_NB}${Yellow} Commits to check ...${Color_Off}"

i=0
# Iterate over each Commit
for commit in $(echo "${COMMITS}" | jq -r '.[] | @base64'); do
    _jq() {
        echo "${commit}" | base64 --decode | jq -r ${1}
    }
    i++

    echo -e "[#${i}] ${Yellow}$(_jq '.commit.message')${Color_Off}"
done
