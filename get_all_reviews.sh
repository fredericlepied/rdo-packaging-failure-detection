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

set -x

rm -f current_reviews*
ssh -p 29418 flepied@review.openstack.org gerrit query --format JSON --current-patch-set --files --commit-message -- status:open branch:master > current_reviews

if [ $(tail -1 current_reviews | jq -r .moreChanges) = true ]; then
    idx=1
    limit=$(tail -1 current_reviews | jq -r .rowCount)
    while :; do
        ssh -p 29418 flepied@review.openstack.org gerrit query --format JSON --current-patch-set --files --commit-message -S $(($idx * $limit)) -- status:open branch:master limit:$limit > current_reviews$idx
        if [ $(tail -1 current_reviews$idx | jq -r .moreChanges) != true ]; then
            break
        fi
        idx=$(($idx + 1))
    done
fi

mkdir -p review

for f in current_reviews*; do
    $(dirname $0)/split_reviews.py review < $f
done

# get_all_reviews.sh ends here
