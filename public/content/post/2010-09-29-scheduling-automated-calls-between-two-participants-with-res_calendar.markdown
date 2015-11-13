---
author: leifmadsen
comments: true
date: 2010-09-29 14:25:50+00:00
layout: post
slug: scheduling-automated-calls-between-two-participants-with-res_calendar
title: Scheduling automated calls between two participants with res_calendar
wordpress_id: 233
categories:
- Asterisk
- Programming
- Useful Tools
tags:
- Asterisk
- calendar
- CALENDAR_EVENT()
- dialplan
- documentation
- howto
- meetings
- res_calendar
---

Here is a little dialplan snippet I wrote this morning for the next edition of the Asterisk book. While I'm not going to delve into all the aspects of setting up res_calendar like we do in the book, I thought for those of you who might already have this working might enjoy it.

(The calendaring modules are available in Asterisk 1.8, which is currently in release candidate status. Check out [http://www.asterisk.org/downloads](http://www.asterisk.org/downloads) for the current version.)

I started with this little bit of dialplan that gets triggered when a call is answered from the calendaring module:

﻿﻿﻿

```
[AutomatedMeetingSetup]
exten => start,1,Verbose(2,Triggering meeting setup for two participants)
   same => n,Set(DeviceToDial=${FILTER(0-9A-Za-z,${CALENDAR_EVENT(location)})})
   same => n,Dial(SIP/${DeviceToDial},30)
   same => n,Hangup()
```

The location field in my calendar event (which in this case is labeled as Destination in my Google Calendar) contains the string 0000FFFF0002 which is the device identifier in my example.

Once you get that working, the cool magic happens below. In the following example, a call is placed from the calendaring module when a meeting needs to take place between two participants. The first part of the dialplan allows the first person called to accept or reject the meeting, and if accepted, to record a message for the other party. Once that recording is saved, the dialplan will go ahead and trigger a call to the other meeting participant.

When that meeting participant answers the call, a Macro() is employed to allow them to listen to the recorded message left by the first party, (i.e. "Hey Jim, this is Leif. We have a meeting scheduled right now."). That person is then presented the same option to accept or reject the call by pressing 1 or 2.

Of course the dialplan could even by further expanded to play back messages when the calls were rejected, the option for the called party to leave a return message of why they are rejecting the call, and maybe even the ability to post-pone the call for a few minutes. All it takes is some clever dialplan!

```
[AutomatedMeetingSetup]
exten => start,1,Verbose(2,Triggering meeting setup for two participants)
same => n,Read(CheckMeetingAcceptance,to-confirm-wakeup&press-1&otherwise&press-2,,1)
same => n,GotoIf($["${CheckMeetingAcceptance}" != "1"]?hangup,1)

same => n,Playback(silence/1&pls-rcrd-name-at-tone&and-prs-pound-whn-finished)
same => n,Set(__RandomNumber=${RAND()})
same => n,Record(/tmp/meeting-invite-${RandomNumber}.ulaw)

same => n,Set(DeviceToDial=${FILTER(0-9A-Za-z,${CALENDAR_EVENT(location)})})
same => n,Dial(SIP/${DeviceToDial},30,M(CheckConfirm))
same => n,Hangup()

exten => hangup,1,Verbose(2,Call was rejected)
same => n,Playback(vm-goodbye)
same => n,Hangup()

[macro-CheckConfirm]
exten => s,1,Verbose(2,Allowing called party to accept or reject)
same => n,Playback(/tmp/meeting-invite-${RandomNumber})
same => n,Read(CheckMeetingAcceptance,to-confirm-wakeup&press-1&otherwise&press-2,,1)
same => n,GotoIf($["${CheckMeetingAcceptance}" != "1"]?hangup,1)

exten => hangup,1,Verbose(2,Call was rejected by called party)
same => n,Playback(vm-goodbye)
same => n,Hangup()
```
