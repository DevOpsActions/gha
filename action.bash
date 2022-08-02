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

echo
echo -e "${IBlue}Found ${UYellow}${COMMITS_NB}${IBlue} commit(s) to check ...${Color_Off}"
echo

# Create temporary file for pretty output through column binary
TMP_LOGS=$(mktemp)

errors=0
ignored=0
valid=0

# Table Header
echo -e "${Cyan}SHA${Color_Off}\t${Purple}Verdict${Color_Off}\t${Green}Author${Color_Off}\t${Yellow}Message${Color_Off}" >> ${TMP_LOGS}

# Iterate over each Commit
for commit in $(echo "${COMMITS}" | jq -r '.[] | @base64'); do
    _jq() {
        echo "${commit}" | base64 --decode | jq -r ${1}
    }

    author=$(_jq '.commit.author.name')
    message=$(_jq '.commit.message')
    sha_long=$(_jq '.parents[0].sha')
    sha_short=${sha_long:0:7}
    check_result=$(check_conventions "${author}" "${message}")

    if [[ "${check_result}" == "🟢" ]]; then
        ((valid=valid+1))
    elif [[ "${check_result}" != "🟠"]]; then
        ((ignored=ignored+1))
    elif [[ "${check_result}" != "🔴"]]; then
        ((errors=errors+1))
    fi

    echo -e "${Cyan}${sha_short}${Color_Off}\t${check_result}\t${Green}${author}${Color_Off}\t${Yellow}${message}${Color_Off}" >> ${TMP_LOGS}
done

cat ${TMP_LOGS} | column -ts $'\t'

echo
echo -e "  🟢 ${Green}${valid} Valid commits${Color_Off}"
echo -e "  🟠 ${Yellow}${ignored} Ignored commits${Color_Off}"
echo -e "  🔴 ${Red}${errors} Invalid commits${Color_Off}" 
echo

if [ "${errors}" -gt 0 ]; then
    echo "::error::At least one commit is not respecting commit convention."
    exit 1
fi
