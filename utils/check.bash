#!/usr/bin/env bash

# Configuration zone
read -r -d '' REGEX <<'EOF'
^(Revert ")?(feat|(hot)?fix|chore|docs|refactor|test|dependencies)((\(\w+( \w+)*\)))?\:.+( \([A-Z]{1,10}-[0-9]{1,5}\))?"?$
EOF
# - Do not edit below this point

check_commit_conventions() {
    author=${1:?}
    message=${2:?}

    if [[ "${author}" == 'dependabot[bot]' ]]; then
        echo "🟠"
        return
    fi

    if echo "${message}" | grep -E -q "^Merge"; then
        echo "🟠"
        return
    fi

    if echo "${message}" | grep -E -q "^workflows((\(\w+( \w+)*\)))?\:.+ ?$"; then
        echo "🟠"
        return
    fi

    if echo "${message}" | grep -v -E -q "${REGEX}"; then
        echo "🔴"
        return
    fi

    echo "🟢"
    return
}

check_pr_naming_conventions() {
    author=${1:?}
    title=${2:?}

    if [[ "${author}" == 'dependabot[bot]' ]]; then
        echo "🟠"
        return
    fi

    if echo "${title}" | grep -E -q "^Release|^Merge back"; then
        echo "🟠"
        return
    fi

    if echo "${title}" | grep -E -q "^workflows((\(\w+( \w+)*\)))?\:.+ ?$"; then
        echo "🟠"
        return
    fi

    if echo "${title}" | grep -v -E -q "${REGEX}"; then
        echo "🔴"
        return
    fi

    echo "🟢"
    return
}