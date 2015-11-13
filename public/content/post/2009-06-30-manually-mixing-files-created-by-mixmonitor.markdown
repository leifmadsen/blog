---
author: leifmadsen
comments: true
date: 2009-06-30 18:19:40+00:00
layout: post
slug: manually-mixing-files-created-by-mixmonitor
title: Manually mixing files created by MixMonitor()
wordpress_id: 37
categories:
- Asterisk
tags:
- MixMonitor() sox mixing asterisk script
---

So last night I did a system update between 11:30pm and 5:00am. One of the things I forgot to do when I was moving to the new system was to install [sox](http://sox.sourceforge.net/) so that `MixMonitor()` could mix the `-in` and `-out` files automatically for me. I still had the recordings, but I needed to get them mixed. I first installed _sox_ so that all new recorded files would be mixed for me. I also needed the _soxmix_ application to mix the files together for me. :)

I created a little bash script to do this for me. Some of my files had different numbers of fields, but I think the common format for Asterisk is 5 fields (separate with a hyphen) followed by either `-in.wav` or -`out.wav`. The following script takes the files in the `/var/spool/asterisk/monitor/merge/` directory, and mixes them together to a single file, then places them in the `/var/spool/asterisk/monitor/` directory.

```bash
#!/bin/bash

for NAME in $(find /var/spool/asterisk/monitor/merge/ -maxdepth 1 -type f | cut -d "/" -f7 | cut -d "-" -f1-5)
#                                                                                         fields we want  ^^^
do
        IN=$NAME-in.wav
        OUT=$NAME-out.wav
        MERGE=$NAME.wav
        MERGE_PATH=/var/spool/asterisk/monitor/merge
        WRITE_PATH=/var/spool/asterisk/monitor

        if [ -e $MERGE_PATH/$IN -a -e $MERGE_PATH/$OUT ]
        then
                echo "Both IN and OUT files exist. Creating $MERGE"
                soxmix $MERGE_PATH/$IN $MERGE_PATH/$OUT $WRITE_PATH/$MERGE
                mv $MERGE_PATH/$IN $MERGE_PATH/done/
                mv $MERGE_PATH/$OUT $MERGE_PATH/done/
        else
                echo "Skipping the creating of $MERGE due to IN and OUT not being found"
        fi
        echo ""
done
```
