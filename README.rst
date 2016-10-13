Tools to detect potential RDO packaging issues in OpenStack gerrit reviews
==========================================================================

First launch the MQTT event monitoring from the OpenStack firehose to
be sure to miss no event from OpenStack gerrit::
  
  $ virtualenv v
  $ . v/bin/activate
  $ pip install -r requirements.txt
  $ ./monitor.py event
  
Then in another terminal, download all the open reviews for the master
branch::

  $ ./get_all_reviews.sh

Then you can process the reviews and events by launching::
  
  $ . v/bin/activate
  $ ./process_changes.sh $PWD

This will classify the reviews into 2 directories for the ones that
could potentially cause packaging issues. ``requirements`` for reviews
that are modifying their requirements so packages could need new
dependencies. ``filelist`` for reviews that have added or removed
files.

To create an html report, just launch::
  
  $ . v/bin/activate
  $ ./gen_report.py once

To continuously generate the report, launch like this::

  $ . v/bin/activate
  $ ./gen_report.py
