#!/usr/bin/env bash

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
echo -e "${UCyan}SHA${Color_Off}\t${UGreen}Author${Color_Off}\t${UYellow}Message${Color_Off}\t${UPurple}Verdict${Color_Off}" >> ${TMP_LOGS}

# Iterate over each Commit
for commit in $(echo "${COMMITS}" | jq -r '.[] | @base64'); do
    _jq() {
        echo "${commit}" | base64 --decode | jq -r ${1}
    }

    author=$(_jq '.commit.author.name')
    message=$(_jq '.commit.message')
    sha_long=$(_jq '.parents[0].sha')
    sha_short=${sha_long:0:7}
    check_result=$(check_commit_conventions "${author}" "${message}")

    if [[ "${check_result}" == "🟢" ]]; then
        ((valid=valid+1))
    elif [[ "${check_result}" == "🟠" ]]; then
        ((ignored=ignored+1))
    elif [[ "${check_result}" == "🔴" ]]; then
        ((errors=errors+1))
    fi

    echo -e "${Cyan}${sha_short}${Color_Off}\t${Green}${author}${Color_Off}\t${Yellow}${message}\t${check_result}${Color_Off}" >> ${TMP_LOGS}
done

cat ${TMP_LOGS} | column -ts $'\t' && \
rm ${TMP_LOGS}

echo
echo -e "  🟢 ${Green}${valid} Valid commit(s)${Color_Off}"
echo -e "  🟠 ${Yellow}${ignored} Ignored commit(s)${Color_Off}"
echo -e "  🔴 ${Red}${errors} Invalid commit(s)${Color_Off}" 
echo

if [ "${errors}" -gt 0 ]; then
    echo "::error::ERROR: ${errors} commits are not respecting commit convention"
    exit 1
fi
