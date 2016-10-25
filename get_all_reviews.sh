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
curl -s -L 'https://review.openstack.org/changes/?q=status:open+branch:master&o=CURRENT_REVISION&o=CURRENT_FILES&o=LABELS' | sed 1d > current_reviews

limit=$(jq -r '. | length' current_reviews)

if [ $(jq -r ".[$(($limit -1))]._more_changes" current_reviews) = true ]; then
    idx=1
    while :; do
        curl -s -L "https://review.openstack.org/changes/?q=status:open+branch:master&o=CURRENT_REVISION&o=CURRENT_FILES&o=LABELS&S=$(($idx * $limit))" | sed 1d > current_reviews$idx
        last=$(jq -r '. | length' current_reviews$idx)
        if [ $(jq -r ".[$(($last -1))]._more_changes" current_reviews$idx) != true ]; then
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
