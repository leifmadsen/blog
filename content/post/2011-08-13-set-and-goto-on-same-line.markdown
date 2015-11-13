---
author: leifmadsen
comments: true
date: 2011-08-13 02:14:55+00:00
layout: post
slug: set-and-goto-on-same-line
title: Set() and Goto() on same line
wordpress_id: 350
categories:
- Asterisk
- Programming
tags:
- Asterisk
- dialplan
- tips
---

(Thanks to Jared Smith for answering my question in IRC which is the inspiration for this post.)

Typically when I write dialplan, primarily in the case where I'm using a pattern match, I'll save the dialed extension to a channel variable using `Set()`, then do a `Goto()` where the call logic is handled. The `Set()` is so that I don't lose the value of `${EXTEN}` throughout the dialplan process, especially if I'm using other mechanics such as `GoSub()` and others.

I've been doing this on two or three lines like this (usually three because I like using a `NoOp()` or `Verbose()` for the first priority):

```
exten => _NXXNXXXXXX,1,NoOp()
   same => n,Set(DialedExtension=${EXTEN})
   same => n,Goto(CallHandler,1)
```

This is kind of annoying for each pattern match, especially if you're going to do multiple. Here is a legitimate example of the `CallHandler` extension:

```
exten => _NXXNXXXXXX,1,NoOp()
   same => n,Set(DialedExtension=${EXTEN})
   same => n,Goto(CallHandler,1)

exten => _1NXXNXXXXXX,1,NoOp()
   same => n,Set(DialedExtension=${EXTEN})
   same => n,Goto(CallHandler,1)

exten => _NXXXXXX,1,NoOp()
   same => n,Set(DialedExtension=${EXTEN})
   same => n,Goto(CallHandler,1)

exten => CallHandler,1,NoOp()
   same => n,Dial(${GLOBAL(PSTN_CONNECTION)}/${DialedExtension},30)
   same => n,Hangup()
```

It's a bit annoying having to either type out the same type of logic multiple times, even if it's only 2-3 lines (even if you just copy and paste the `same =>` lines it's a bit better, but still not ideal). So here's a solution to the same problem of multiple pattern matches and doing a `Goto()` our `CallHandler` extension.

```
exten => _NXXNXXXXXX,1,GotoIf($[${EXISTS(${SET(DialedExtension=${EXTEN})})}]?CallHandler,1:i,1)
exten => _1NXXNXXXXXX,1,GotoIf($[${EXISTS(${SET(DialedExtension=${EXTEN})})}]?CallHandler,1:i,1)
exten => _NXXXXXX,1,GotoIf($[${EXISTS(${SET(DialedExtension=${EXTEN})})}]?CallHandler,1:i,1)

exten => CallHandler,1,NoOp()
   same => n,Dial(${GLOBAL(PSTN_CONNECTION)}/${DialedExtension},30)
   same => n,Hangup()

exten => i,1,Congestion()
```

While both ways are perfectly reasonable (and some may argue the more verbose method is easier to read), I like embedding dialplan into a single line when I can as I find it easier to maintain. I'm also pretty good at knowing how many brackets to end with when nesting functions, but not everyone is comfortable doing that; in those cases you should probably break it out to multiple lines in order to save debugging time. Both methods are perfectly valid, so enjoy using whichever you prefer!
