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


def process_line(line):
    data = json.loads(line)
    filelist = False
    if 'number' in data:
        for fdata in data['currentPatchSet']['files']:
            if fdata['file'] == '/COMMIT_MSG':
                continue
            if fdata['file'] == 'requirements.txt' or \
               fdata['file'] == 'test-requirements.txt':
                return 'requirements'
            if fdata['type'] == 'ADDED' or fdata['type'] == 'DELETED':
                filelist = True
        if filelist:
            return 'filelist'
        else:
            return 'nochange'
    else:
        return 'error'

if __name__ == "__main__":
    import sys

    with open(sys.argv[1]) as f:
        line = f.readline()
    print process_line(line)

# process_review.py ends here
