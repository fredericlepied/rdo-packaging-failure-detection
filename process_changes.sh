#!/bin/bash
#
# Copyright (C) 2016 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

function log() {
    echo "$@" >> "$topdir/log"
}

if [ $# != 2 ]; then
    echo "Usage: $0 <top dir dir> <git top dir>" 1>&2
    exit 1
fi

topdir="$1"
spooldir="$1/spool"
workdir="$1/work"
faileddir="$1/failed"
errordir="$1/error"
gittopdir="$2"

for dir in "$@"; do
    if [ ! -d "$dir" ]; then
        echo "$dir doesn't exist"
        exit 1
    fi
done

set -e

mkdir -p $spooldir $workdir $faileddir $errordir

set -x

while :; do
    fname=$(ls -rt "$spooldir"|head -1)
    if [ -z "$fname" -o ! -r "$spooldir/$fname" ]; then
        sleep 10
        continue
    elif ! mv "$spooldir/$fname" "$workdir" 2> /dev/null; then
        continue
    fi

    project=$(jq -r .change.project "$workdir/$fname")
    basedir=$(basename $project)
    
    # filter out the reviews we don't care about
    
    case $basedir in
        deb-*|rpm-packaging)
            rm -f "$workdir/$fname"
            continue
            ;;
    esac

    if [ $(jq -r .change.branch "$workdir/$fname") != master ]; then
        rm -f "$workdir/$fname"
        continue
    fi
    
    # remove the previous file for the same review if any
    
    rm -f "$faileddir/$fname" "$errordir/$fname"
    
    # do the check on the real repository
    
    if [ ! -d $gittopdir/$basedir ]; then
        git clone https://github.com/${project}.git $gittopdir/$basedir
    fi

    cd $gittopdir/$basedir
    git checkout .
    git clean -dxf
    if ! git review -d $fname; then
        cd ..
        rm -rf $basedir
        git clone https://github.com/${project}.git $gittopdir/$basedir
        cd $basedir
        cd $gittopdir/$basedir
        if ! git review -d $fname; then
            mv "$workdir/$fname" "$errordir"
            log $project $fname error
            continue
        fi
    fi
    if git show --oneline | egrep -q '^(\+\+\+|---) /dev/null'; then
        mv "$workdir/$fname" "$faileddir"
        log $project $fname failed
    else
        rm -f "$workdir/$fname"
        log $project $fname success
    fi
done

# process_changes.sh ends here
