#!/usr/bin/env bash

# Extracting Commits API URL from current context
PR_TITLE=$(echo "${GITHUB_CONTEXT:?}" | jq .event.pull_request.title -r)
AUTHOR=$(echo "${GITHUB_CONTEXT:?}" | jq .actor -r)
PR_ID=$(echo "${GITHUB_CONTEXT:?}" | jq .event.pull_request -r)

# Create temporary file for pretty output through column binary
TMP_LOGS=$(mktemp)

errors=0
ignored=0
valid=0

echo

# Table Header
echo -e "${UCyan}ID${Color_Off}\t${UGreen}Author${Color_Off}\t${UYellow}Title${Color_Off}\t${UPurple}Verdict${Color_Off}" >> ${TMP_LOGS}

check_result=$(check_pr_naming_conventions "${AUTHOR}" "${PR_TITLE}")

if [[ "${check_result}" == "🟢" ]]; then
    ((valid=valid+1))
elif [[ "${check_result}" == "🟠" ]]; then
    ((ignored=ignored+1))
elif [[ "${check_result}" == "🔴" ]]; then
    ((errors=errors+1))
fi

echo -e "${Cyan}${PR_ID}\t${Green}${AUTHOR}${Color_Off}\t${Yellow}${PR_TITLE}${Color_Off}\t  ${check_result}" >> ${TMP_LOGS}

cat ${TMP_LOGS} | column -ts $'\t' && \
rm ${TMP_LOGS}

echo
echo -e "  🟢 ${Green}${valid} Valid naming${Color_Off}"
echo -e "  🟠 ${Yellow}${ignored} Ignored naming${Color_Off}"
echo -e "  🔴 ${Red}${errors} Invalid naming${Color_Off}" 
echo

if [ "${errors}" -gt 0 ]; then
    echo "::error::ERROR: Pull Request's Title is not respecting naming convention"
    exit 1
fi
