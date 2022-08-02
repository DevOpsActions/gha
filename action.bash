#!/usr/bin/env bash

# Extracting Commits API URL from current context
COMMITS_API_URL=$(echo "${GITHUB_CONTEXT}" | jq .event.pull_request._links.commits.href -r)

# Check if an error occured during Commits API URL extraction
if [[ "${COMMITS_API}" == "null" ]]; then
    echo "::error:Could not find commits api url from context"
    exit 1
fi

# Get Commits list
COMMITS=$(curl --request GET                                 \
    --header 'authorization: Bearer ${{ env.GITHUB_TOKEN }}' \
    --header 'content-type: application/json'                \
    --silent                                                 \
    --fail                                                   \
    ${COMMITS_API})

# Count them
COMMITS_NB=$(echo "${COMMITS}" | jq '. | length')

echo "Found ${COMMITS_NB} Commits to check ..."

# Iterate over each Commit
for commit in $(echo "${COMMITS}" | jq -r '.[] | @base64'); do
    _jq() {
        echo "${commit}" | base64 --decode | jq -r ${1}
    }

    echo "Commit message is: $(_jq '.commit.message')"
done
