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

function process_review() {
    pwd
    project=$(jq -r .project "$reviewdir/$fname" | sed s@.*/@@)
    change_id=$(jq -r .change_id "$reviewdir/$fname")
    commit=$(jq -r '.revisions | keys[0]' "$reviewdir/$fname")
    ref=$(jq -r ".revisions[\"$commit\"].ref" "$reviewdir/$fname")
    url=$(jq -r ".revisions[\"$commit\"].fetch.\"anonymous http\".url" "$reviewdir/$fname")

    # Map to rdoinfo
    package=$(./scripts/map-project-name $project)
    package_distgit=${package}_distro

    echo -n " $project $package $change_id $commit $url $ref " 1>&3

    dlrn --config projects.ini --package-name $package --head-only --local --use-public --dev --run /bin/true || return $?
    
    cd data/$package
    if [ -n "$ref" -a "$ref" != null -a -n "$url" -a "$url" != null ]; then
        git fetch "$url" "$ref" || return 1
        git checkout FETCH_HEAD || return 1
    else
        return 1
    fi
    git log -1
    cd ../..
    dlrn --config projects.ini --package-name $package --head-only --local --use-public --dev
    ret=$?

    # save some space by removing successful builds
    if [ $ret = 0 ]; then
        rm -rf data/repos/${commit:0:2}/${commit:2:2}/${commit}_dev
    fi

    return $ret
}

if [ $# != 1 ]; then
    echo "Usage: $0 <top dir>" 1>&2
    exit 1
fi

reviewdir="$1/requirements"
logdir="$1/log"
successdir="$1/success"
faileddir="$1/failed"

mkdir -p $logdir $successdir $faileddir

if ! type -p tox; then
    echo "you must install tox before launching $0" 1>&2
    exit 1
fi

set -e

if [ ! -d $1/DLRN ]; then
    git clone https://github.com/openstack-packages/DLRN.git
    cd $1/DLRN
    # Setup virtualenv with tox and use it
    tox -epy27 --notest
    . .tox/py27/bin/activate
    pip install git-review
else
    cd $1/DLRN
    . .tox/py27/bin/activate
fi

set +e

exec 3>&1 4>&2

echo "Processing reviews..."
while :; do
    for fname in $(ls -rt "$reviewdir"); do
        if [ -r nobuild ]; then
            break
        fi
        echo -n "Processing review $fname"
        rm -f "$successdir/$fname" "$faileddir/$fname"
        exec >> "$logdir/$fname.log" 2>&1
        if process_review; then
            mv "$reviewdir/$fname" "$successdir"
            echo success 1>&3
        else
            mv "$reviewdir/$fname" "$faileddir"
            echo failed 1>&3
        fi
        exec 1>&3 2>&4
    done
    
    if [ -r nobuild ]; then
        break
    fi
done

# build_reviews.sh ends here
