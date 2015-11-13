---
author: leifmadsen
comments: true
date: 2011-09-15 12:34:35+00:00
layout: post
slug: return-just-pid-of-script-with-ps-and-awk
title: Return just PID of script with 'ps' and 'awk'
wordpress_id: 377
categories:
- Being Productive
- Programming
tags:
- awk
- bash
- grep
- hack
- ps
- scripting
---

Today I ran into an issue where I am running a python script that I needed to get the process ID (PID) of, but that the process was being output with a space between 'python' and the actual script name (in this case, jiraircbot.py).

I'm sure it's totally overkill and there is a much easier way I didn't find to do this, but after some scouring of The Google, I found something that works! (The purpose of this was to kill off a rogue script process each night so I could restart it.)

Here is what the output looks like with just `ps aux | grep python`

```
# ps aux | grep python
root      1120  0.0  0.2  50176  4380 ?        Sl   Aug04  24:52 /usr/bin/python /usr/bin/fail2ban-server -b -s /var/run/fail2ban/fail2ban.sock
root     18182  2.2  1.5  35328 32148 pts/0    S    08:21   0:11 python jiraircbot.py
root     18219  0.0  0.0   3328   804 pts/0    S+   08:29   0:00 grep python
```

A little bit more data than I wanted, plus of course 'grep python' is always going to be returned if I just use grep straight up. Putting many pieces together from a few websites, this is what I came up with to just return the PID of the jiraircbot.py script:

```bash
ps -eo pid,command | grep "jiraircbot.py" | grep -v grep | awk '{print $1}'
```

What I'm doing, is controlling what is returned, so in this case have `ps` just return the pid and command fields. Run that through `grep` to just get the script I wanted, pipe that back through `grep` to remove the line including `grep python` and then pipe that through `awk` to just return the first field (which would be the pid of the process I wanted).

All in all, a nice hack :)
