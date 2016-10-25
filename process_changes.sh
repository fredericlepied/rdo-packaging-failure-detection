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
    echo "$@" >> "$topdir/changes.log"
}

function process_review() {
    result=$($(dirname $0)/process_review.py "$reviewdir/$fname")
    log $project $fname $result
    
    case $result in
        nochange|notinrdo)
            rm "$reviewdir/$fname"
            ;;
        *)
            mkdir -p "$topdir/$result"
            mv "$reviewdir/$fname" "$topdir/$result"
            ;;
    esac
}

if [ $# != 1 ]; then
    echo "Usage: $0 <top dir>" 1>&2
    exit 1
fi

topdir="$1"
eventdir="$1/event"
workdir="$1/work"
reviewdir="$1/review"
filelistdir="$1/filelist"
requirementsdir="$1/requirements"
errordir="$1/error"
logdir="$1/log"

for dir in "$@"; do
    if [ ! -d "$dir" ]; then
        echo "$dir doesn't exist"
        exit 1
    fi
done

set -e

mkdir -p $eventdir $workdir $filelistdir $requirementsdir $errordir $logdir $reviewdir

exec 3>&1 4>&2

# process reviews

echo "Processing reviews..."
for fname in $(ls -rt "$reviewdir"); do
    echo "Processing review $fname"
    exec >> "$logdir/$fname.log" 2>&1
    process_review
    exec 1>&3 2>&4
done

# process events

echo "Processing events..."
while :; do
    exec 1>&3 2>&4
    fname=$(ls -rt "$eventdir"|head -1)
    if [ -z "$fname" -o ! -r "$eventdir/$fname" ]; then
        sleep 10
        continue
    elif ! mv "$eventdir/$fname" "$workdir" 2> /dev/null; then
        continue
    fi
    
    echo "Processing event $fname"
    exec >> "$logdir/$fname.log" 2>&1
    
    project=$(jq -r .change.project "$workdir/$fname")
    basedir=$(basename $project)
    
    # filter out the reviews we don't care about
    
    case $basedir in
        deb-*|rpm-packaging)
            rm -f "$workdir/$fname"
            log $project $fname skipped
            continue
            ;;
    esac
    
    # remove the previous file for the same review if any
    
    rm -f "$filelistdir/$fname" "$requirementsdir/$fname" "$errordir/$fname"

    if ! curl -s -L "https://review.openstack.org/changes/?q=$(jq -r .change.id "$workdir/$fname")+branch:master&o=CURRENT_REVISION&o=CURRENT_FILES&o=LABELS" | sed 1d > "$reviewdir/$fname"; then
        mv "$workdir/$fname" "$errordir"
        log $project $fname error
        continue
    fi
    
    rm "$workdir/$fname"

    process_review
done

# process_changes.sh ends here
