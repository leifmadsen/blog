---
author: leifmadsen
comments: true
date: 2011-08-11 15:48:54+00:00
layout: post
slug: connecting-two-conferences-on-initial-join-with-cleanup
title: Connecting two conferences on initial join (with cleanup)
wordpress_id: 340
categories:
- Asterisk
- Musings
- Programming
---

> Update 2011/12/15:  Updated the code to deal with a couple of people joining at about the same time by using GROUP() and GROUP_COUNT(). Additionally updated the 'h' extension which was missing some code

For the last week or so at work, people have been saying, "Hey, I can't join the conference call this morning because I'm driving but I can't call into the conference room on that server". There are really a couple solutions to the problem, 1) everyone should use the conference room that is accessible via the PSTN, 2) get the IT staff to allow PSTN access to the internal conference room.

Those would be reasonable solutions, but who wants to be reasonable?! Terry Wilson suggested that we just keep a persistent connection between the two PBXs so that conferences could be joined. (I also earlier suggested that someone could just bridge the conference rooms together from their phone, but that required someone to remember to do that.) So instead of keeping the conferences connected indefinitely, I thought of a way to only connect them when the conference started, and then to kill it when the last person left.

Below you will see the dialplan I wrote that sets up the call between the conference rooms, then tears them down when the last person leaves. (In case you care, we're connecting a MeetMe() room on a Switchvox server with the ConfBridge() application running on an Asterisk 10 based box -- we use ConfBridge() to permit high quality audio and video conferencing during the daily stand up calls.)

```
[IncomingCalls]
exten => 500004,1,Verbose(2,${CALLERID(all)} is looking for a conference!)
   same => n,Playback(silence/1)
   same => n,Read(ConferenceRoom,conf-getconfno&beep)
   same => n,GotoIf($[${DIALPLAN_EXISTS(ConferenceRooms,${ConferenceRoom},1)}]?${ConferenceRoom},1:no_conf_room,1)
   same => n,Hangup()

include => ConferenceRooms

[ConferenceRooms]
exten => 12345,1,Answer()
   same => n,Verbose(2,${CALLERID(all)} is joining the wideband public conference room with ${CONFBRIDGE_INFO(paries,12345)} people)
   same => n,Set(GROUP(conference)=12345)
   same => n,ExecIf($[0${CONFBRIDGE_INFO(parties,12345)} < 1 & ${GROUP_COUNT(12345@conference)} <= 1]?Originate(Local/bridge_conference@ConferenceRooms,app,ConfBridge,12345))
   same => n,ConfBridge(12345)
   same => n,Hangup()

exten => bridge_conference,1,NoOp()
   same => n,Dial(SIP/7070@remote-server.tld,,D(wwww12345#))

exten => no_conf_room,1,Verbose(2,${CALLERID(all)} attempted to join an non-existant conference room)
   same => n,Playback(conf-invalid)
   same => n,Goto(500004,1)

exten => h,1,NoOp()
   same => n,ExecIf($[0${CONFBRIDGE_INFO(parties,11111)} <= 1]?SoftHangup(SIP/remote-server.tld,a))
```
