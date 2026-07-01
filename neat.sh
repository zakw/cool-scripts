#!/usr/bin/env bash

# SPDX-FileCopyrightText: Copyright (c) Zak Whaley
# SPDX-License-Identifier: MIT

set -e # Exit immediately for errors

shopt -s extglob # Enable extended glob expressions

usage(){
    echo "Usage: $0 [-h|--help] [-n|--dry-run] [-f|--force] [-u|--untracked] [-k|--keep <pattern> ...] [-s|--show-command] [-l|--list-patterns]"
}

dryRun="false"
keepUntracked="true"
keepPatternsAdditional=()
showCommand="false"
listPatterns="false"
force="false"

# Patterns are generally the form of .gitignore patterns except negation patterns ('!') and we add
# an additional term as a convenience for subdirectories if the last character is '/'
#
# See: https://git-scm.com/docs/gitignore#_pattern_format
addKeepPattern(){
    local -n out_keepPatternList="${1:?"Error: Output keep list required"}"
    local keepPattern="$2"

    # Trim whitespace
    keepPattern="${keepPattern##+([[:space:]])}" # leading
    keepPattern="${keepPattern%%+([[:space:]])}" # trailing

    # Skip empty patterns
    if [[ -z "$keepPattern" ]]; then
        return
    fi

    # Since the script relies on toggling negation, we can't support user-specified negation
    if [[ "$keepPattern" == !* ]]; then
        echo "Error: Cannot support .gitignore negation patterns: '$keepPattern'" >&2
        exit 1
    fi

    # Register our pattern
    out_keepPatternList+=("$keepPattern")

    # If we add a folder, add all sub-directories, too
    if [[ "$keepPattern" == */ ]]; then
        out_keepPatternList+=("$keepPattern**")
    fi
}

while [[ $# -gt 0 ]]; do
    parameter="$1"
    shift 1

    case "$parameter" in
        -h|--help)
            usage
            exit 0
            ;;
        -n|--dry-run)
            dryRun="true"
            ;;
        -u|--Untracked)
            keepUntracked="false"
            ;;
        -f|--force)
            force="true"
            ;;
        -k|--keep)
            if [[ -z "$1" ]]; then
                echo "Error: \"$parameter\" requires a value." >&2
                usage
                exit 1
            fi

            addKeepPattern keepPatternsAdditional "$1"
            shift 1
            ;;
        -s|--show-command)
            showCommand="true"
          ;;
        -l|--list-patterns)
            listPatterns="true"
            ;;
        *)
            echo "Error: Unknown option \"$parameter\"" >&2
            usage
            exit 1
            ;;
    esac
done

# Aggregate multiple "keep" lists so local users can have their own
keepPatternsCombined=()
for keepFile in .neat*; do

    # Load this .neat file into memory
    mapfile -t lines < "$keepFile"

    # Process each line of the .neat file
    for line in "${lines[@]}"; do
        # Remove everything after a '#' comment marker
        line="${line%%#*}"

        addKeepPattern keepPatternsCombined "$line"
    done < $keepFile
done

# Append our command-line patterns so the file patterns are evaluated first
keepPatternsCombined+=("${keepPatternsAdditional[@]}")

if [[ "$listPatterns" == "true" ]]; then
    for keepPattern in "${keepPatternsCombined[@]}"; do
        echo "$keepPattern"
    done

    exit 0
fi

# With "X", all ignored files are deleted so we negate its exclusion to treat it as "not ignored"
gitFlags=-Xd
excludeNegationFlag="!"
if [[ "$keepUntracked" != "true" ]]; then
    # With "x", all untracked files are deleted so we just match it normally
    gitFlags=-xd
    excludeNegationFlag=""
fi

# Build our exclusion list of things to keep
keepPatternArgs=()
for keepPattern in "${keepPatternsCombined[@]}"; do
    keepPatternArgs+=(-e "$excludeNegationFlag$keepPattern")
done

cleanWithFlags(){
    local gitFlags="${1:?"Error: Missing git flags"}"
    local showCommand="${2:?"Error: Missing show flag"}"

    # We'll expand the remaining parameters as $@, later
    shift 2

    # It's little jank, but there's a few things going on here:
    # 1) The simplest way to get "pretty" shell-safe output is to just trace it as "$@" will
    #    expand with properly single-quoted entries as necessary.
    # 2) I don't want to have to deal with turning trace back off and hiding the output of doing
    #    so, therefore we just execute in a subshell
    # 3) The $PS4 depth prints '+' by default so we also clear it first
    (
        if [[ "$showCommand" == "true" ]]; then
            PS4=
            set -x
        fi

        git clean "$gitFlags" "$@"
    )
}

# If a dry-run was requested, we're finished
if [[ "$dryRun" == "true" ]]; then
    # Add git clean's dry-run flag to do a dry-run first
    cleanWithFlags "${gitFlags}n" "$showCommand" "${keepPatternArgs[@]}"

    exit 0
# Ask the user if this looks good before proceeding
elif [[ "$force" != "true" ]]; then
    # Print our dry run to the terminal and capture output
    output=$(cleanWithFlags "${gitFlags}n" "$showCommand" "${keepPatternArgs[@]}" | tee /dev/tty)

    # Nothing to clean if there was no output
    if [[ -z "$output" ]]; then
        exit 0
    fi

    while true; do
        read -p "Continue to clean? [y/N] " response

        case "$response" in
            [yY])
                echo "Cleaning..."
                break
                ;;
            [nN]|"")
                exit 0
                ;;
            *)
                echo "Unknown response: \"$response\""
                ;;
        esac
    done
fi

# Add git clean's force flags (two "f"s descend into submodules, too)
cleanWithFlags "${gitFlags}ff" "$showCommand" "${keepPatternArgs[@]}"
