Tools to detect potential packaging issues in OpenStack gerrit reviews
======================================================================

First launch the MQTT event monitoring to be sure to miss no event::
  
  $ virtualenv v
  $ ./v/bin/activate
  $ pip install -r requirements.txt
  $ ./monitor.py event
  
Then in another terminal, download all the open reviews for the master
branch::

  $ ./get_all_reviews.sh

Then you can process the reviews and events by launching::
  
  $ ./process_changes.sh

This will classify the reviews into 2 directories for the ones that
could potentially cause packaging issues. ``requirements`` for reviews
that are modifying their requirements so packages could need new
dependencies. ``filelist`` for reviews that have added or removed
files.
