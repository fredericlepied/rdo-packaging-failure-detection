#!/usr/bin/env python
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

'''
'''

import json
from rdopkg.actionmods import rdoinfo


def jenkins_vote(review):
    if ('labels' in review and 'Verified' in review['labels'] and
       'value' in review['labels']['Verified']):
        return review['labels']['Verified']['value']
    return 0


def jenkins_lowest_vote(review):
    if ('labels' in review and 'Code-Review' in review['labels'] and
       'value' in review['labels']['Code-Review']):
        return review['labels']['Code-Review']['value']
    return 0


def process_line(line, info):
    data = json.loads(line)

    if (jenkins_lowest_vote(data) == -2 or
       jenkins_vote(data) == -1):
        return 'lowscore'

    project = data['project'].split('/')[1]

    if len([x for x in info['packages'] if x['project'] == project]) == 0:
        return 'notinrdo'

    filelist = False
    if 'current_revision' in data and 'revisions' in data:
        files = data['revisions'][data['current_revision']]['files']
        for fname in files:
            if ((fname == 'requirements.txt' or
                 fname == 'test-requirements.txt') and
               data['subject'] != 'Updated from global requirements'):
                return 'requirements'
            if ('status' in files[fname] and
               fname[0:len('releasenotes')] != 'releasenotes'):
                filelist = True
        if filelist:
            return 'filelist'
        else:
            return 'nochange'
    else:
        return 'error'

if __name__ == "__main__":
    import sys

    inforepo = rdoinfo.get_default_inforepo()
    inforepo.init()
    info = inforepo.get_info()

    with open(sys.argv[1]) as f:
        line = f.read(-1)
    print process_line(line, info)

# process_review.py ends here
