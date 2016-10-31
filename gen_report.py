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

import os

import jinja2
import json
from time import gmtime
from time import strftime


def process_dir(directory, reviews):
    count = 0
    for (dirpath, dirnames, filenames) in os.walk(directory):
        for fname in filenames:
            path = os.path.join(dirpath, fname)
            with open(path) as f:
                review = json.loads(f.read(-1))
            review['directory'] = directory
            sha1 = review['revisions'].keys()[0]
            review['sha1'] = '%s/%s/%s' % (sha1[0:2], sha1[2:4], sha1)
            review['url'] = 'https://review.openstack.org/%d' % review['_number']
            review['updated'] = review['updated'][:-len('.000000000')]
            if ('wip' not in review['subject'].lower() and
               review['status'] == 'NEW' and
               jenkins_lowest_vote(review) != -2 and
               jenkins_vote(review) == 1):
                reviews.append(review)
                count += 1
    return count


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


def _jinja2_filter_strftime(date, fmt="%Y-%m-%d %H:%M:%S"):
    gmdate = gmtime(date)
    return "%s" % strftime(fmt, gmdate)


def gen():
    reviews = []
    process_dir('failed', reviews)
    print len(reviews)
    reviews = sorted(reviews, key=lambda k: k['updated'], reverse=True)
    # configure jinja and filters
    jinja_env = jinja2.Environment(
        loader=jinja2.FileSystemLoader(['.']))
    jinja_env.filters["strftime"] = _jinja2_filter_strftime
    jinja_template = jinja_env.get_template("report.j2")
    content = jinja_template.render(reviews=reviews)
    with open('report.html', "w") as fp:
        fp.write(content)

if __name__ == '__main__':
    import inotify.adapters
    import sys

    inotifier = inotify.adapters.Inotify()

    gen()

    # when called with an arg, just generate the report once and exit
    if len(sys.argv) != 1:
        sys.exit(0)
    else:
        inotifier.add_watch(b'failed')

        for event in inotifier.event_gen():
            # only react when a file is moved to the directories we
            # are watching
            if event is not None and 'IN_MOVED_TO' in event[1]:
                gen()

# gen_report.py ends here
