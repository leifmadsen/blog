---
author: leifmadsen
comments: true
date: 2009-07-18 03:47:57+00:00
layout: post
slug: howto-getting-jabberxmpp-notifications-from-your-pbx
title: 'HowTo: Getting Jabber/XMPP notifications from your PBX'
wordpress_id: 83
categories:
- Asterisk
tags:
- Asterisk
- howto
- Jabber
- JabberSend()
- XMPP
---

I just have to write up a quick post to show you JUST HOW SIMPLE it is to get interesting events from your PBX via Jabber. Right now I'm using it to notify me of anyone trying out my test ISN number, or whenever they join my conference bridge (good reminder if I lose track of time and forget that I scheduled some people to join my conference room).

This is based on Asterisk 1.4, although the same configuration should work on 1.6, but I like to try and give 1.4 examples where I can for those of you still running 1.4.

So the first thing you need to do is configure Asterisk to connect to a Jabber server. I like to use the Google Jabber servers since it saves me from setting one up :) I have setup Google Apps as well so that I can use my own domain, but using a Gmail address should work just as well.

Configuring res_jabber (the Jabber module in Asterisk) is nice and easy. The main thing to notice is that I uncommented the 'debug' option as the default is to have a bunch of debugging on the console. Find below the entire jabber.conf file from _/etc/asterisk_ based on the sample file, but with the required options uncommented for connecting to talk.google.com. Note that I've created a Jabber account specifically for my Asterisk box, although I'm sure you could use an existing account if you wanted.

```css
[general]
debug=no                                   ;;Turn on debugging by default.
;autoprune=yes                           ;;Auto remove users from buddy list.
;autoregister=yes                        ;;Auto register users from buddy list.

[asterisk]                                   ;;label
type=client                                 ;;Client or Component connection
serverhost=talk.google.com          ;;Route to server for example,
                                                ;;	talk.google.com
username=asterisk@leifmadsen.com        ;;Username with optional roster.
secret=welcome                                    ;;Password
port=5222                                            ;;Port to use defaults to 5222
usetls=yes                                           ;;Use tls or not
usesasl=yes                                         ;;Use sasl or not
buddy=leif@leifmadsen.com                    ;;Manual addition of buddy to list.
statusmessage="I am available"               ;;Have custom status message for
                                                           ;;Asterisk.
;timeout=100                                        ;;Timeout on the message stack.
```

You'll notice that I've added the buddy 'leif@leifmadsen.com' manually. In order to be able to send messages to the 'leif@leifmadsen.com' contact, I need to add them to the buddy list in the Asterisk memory. Once Asterisk goes to send a message via the JabberSend() application, then you will get an authorization request. Once the authorization has been granted, then you will be able to get messages.

Now that we have configured jabber.conf, lets reload the res_jabber module.

From the Asterisk CLI, run:

```*CLI> module reload res_jabber.so```

Then we can verify we have connected to the server correctly by running:

``` *CLI> jabber show connected
Jabber Users and their status:
User: asterisk@leifmadsen.com     - Connected
----
Number of users: 1```

And we can run `jabber test` to do a verification everything is OK:

```*CLI> jabber test
User: leif@leifmadsen.com
Resource: linux918E72D1
client: http://pidgin.im/caps
version: 2.5.5
Jingle Capable: 0
Priority: 1
Status: 1
Message: ```

Oooh a working message stack!

Now that everything looks good to go, lets send a message over Jabber!

From the Dialplan, we need to use the JabberSend() application to send us some information. The example I'll use will send a message whenever someone joins my conference room.

```
[incoming]
exten => 7070,1,Verbose(2,${CALLERID(all)} is joining the conference bridge.)
exten => 7070,n,JabberSend(asterisk,leif@leifmadsen.com,${CALLERID(all)} is joining the conference bridge.)
exten => 7070,n,MeetMe(7070,d)
exten => 7070,n,Hangup()
```

The format for the JabberSend() application is as follows:
* Jabber:  the jabber configuration to use, this is the [name] you configured in jabber.conf
* ScreenName: the screen name of the person you want to send an XMPP message to
* Message: the message you want to send

And that should be pretty much it! Pretty simple eh?
