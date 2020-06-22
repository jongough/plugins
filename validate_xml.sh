#!/bin/bash

if [ -z $CI ] && [ -z $GITHUB_ACTION ]; then
    if [ "$#" -ne "2" ]; then
        echo "Incorrect invocation: Should be validate_xml.sh plugin_name plugin_version"
        echo "where:"
        echo "   plugin_name is the name of the plugin, i.e. testplugin_pi"
        echo "   plugin_version is the version number, i.e. 1.0.114.0"
        echo ""
        echo "   Full command should look like:"
        echo "      validate_xml.sh testplugin_pi 1.0.114.0"
        exit
    fi
    exit_rc=0
    for file in metadata/$1-$2*.xml
    do
        `xmllint  --schema ocpn-plugins.xsd $file --noout 2> /dev/null`
        rc=$?
        if [ $rc -gt 0 ]; then
            `xmllint  --schema ocpn-plugins.xsd $file --noout`
            exit_rc=$rc
        fi
    done
    if [[ $exit_rc == 0 ]]; then
        echo "All files pass xsd check"
    fi
    exit $exit_rc
else
    exit_rc=0
    #gitdiff="$(`git --no-pager diff --name-only ..HEAD`)"
    #echo "gitdiff: ${gitdiff}"
    #gitdifffiles=`$(git diff-tree --no-commit-id --name-only -r ${commit_sha})`
    #echo "gitdifffiles: ${gitdifffiles}"
    echo "Files: ${FILES}"
    echo "commit_sha: ${GITHUB_SHA}"
    echo "GITHUB_REPOSITORY: ${GITHUB_REPOSITORY}"
    echo "REQUEST_NO: ${REQUEST_NO}"
    echo "FILES no: ${#FILES[@]}"
    IFS=' ' read -r -a array <<< "$FILES"
    echo "array size: ${#arrray[@]}"
    URL="https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls/${REQUEST_NO}/files"
    FILES_FOUND=$(curl -s -X GET -G $URL | jq -r '.[] | .filename')
    files_array_val=($FILES_FOUND)
    echo "Validate Files: $FILES_FOUND"
    echo "Files content: $FILES_ARRAY[1]"
    echo "File_array: $#FILE_ARRAY[@]"
    echo "files_found_array: ${#files_array_val[@]}"
    echo "files_array_val[1]: $files_array_val[1]"

    while read -r file; do
        if [[ $file == "metadata"*".xml" ]]; then
            echo "Processing file: $file"
            `xmllint  --schema ocpn-plugins.xsd $file --noout 2> /dev/null`
            rc=$?
            if [ $rc -gt 0 ]; then
                `xmllint  --schema ocpn-plugins.xsd $file --noout`
                exit_rc=$rc
            fi
        fi
    done < <( $(curl -s -X GET -G $URL | jq -r '.[] | .filename') )
    #done < <( git diff --name-only ..master)${{ steps.getfile.outputs.files1 }}
    if [[ $exit_rc == 0 ]]; then
        echo "All files pass git pull xsd check"
    fi
    exit $exit_rc
fi
