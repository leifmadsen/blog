---
author: leifmadsen
comments: true
date: 2010-03-19 16:28:28+00:00
layout: post
slug: using-a-nokia-e71-with-asterisk-3g-or-wifi
title: Using a Nokia E71 with Asterisk (3G or WiFi)
wordpress_id: 187
categories:
- Asterisk
tags:
- 3G
- Asterisk
- configuration
- E71
- howto
- INVITE
- nokia
- sip
- tutorial
- voip
- wifi
---

There was some talk in one of the IRC chat rooms today about someone trying to get their E61i working with Asterisk. I haven't had an issue getting that phone or my E71 phone working, but regardless he was having issues. I figured I might as well spend a little bit of time today going through my configuration, both for my own reference, and so that other people can get their Nokia's setup with Asterisk as well.

I'll be using the native SIP client, although I've had just as good of luck using the Fring application. The advantage to the Fring application is that you can use it with Skype, along with multiple IM clients, and also video! I especially like that the application makes use of the video camera on the front of the phone so that you can use it as a videophone. Using the video on a phone like the iPhone or Nexus One seems useless to me (but I digress!).

First, lets get our Asterisk configuration setup in _sip.conf_. We'll need to make sure we've setup a **realm** in _sip.conf_ as our phone will require it. If you don't, then the default realm is '**asterisk**'.

_sip.conf_:

    
    [general]
    realm=pbx.my_asterisk_box.com
    disallow=all
    allow=ulaw
    allow=alaw
    srvlookup=yes
    pedantic=yes
    maxexpiry=360
    minexpiry=120
    defaultexpirey=120
    videosupport=yes
    
    [leifmadsen_cell]
    type=friend
    secret=super_secret_password
    context=devices
    nat=yes
    canreinvite=no
    qualify=no
    mailbox=100@default
    callerid=Leif Madsen <571>
    insecure=invite,port
    subscribecontext=subscriptions
    disallow=all
    allow=g729
    allow=ulaw




Feel free to change or add whatever options you need for your _sip.conf_. This is generally what I have working right now. I've left out all my domain handling and SIP URI stuff this time around. Maybe I'll talk about it in another blog post in the future.







OK, back to the task at hand. Now that we have our sip.conf file configured, just run 'sip reload' from the Asterisk console, and your settings should be available. You can check to make sure your peer loads up with '**sip show peers**' or '**sip show peer leifmadsen_cell**' (or whatever you called your configuration.







The next step up is to configure our Nokia device. These settings should likely be the same on both the E61i and the E71, but I'm working from a 400 series firmware on the E71, so your mileage may vary.







**Menu > Tools > Settings > Connection > SIP Settings > Options > New SIP Profile > Use default profile**




**
**




With the new profile created, we need to modify it for connection to our Asterisk system. Starting at the top we have the following fields: Profile name, Service profile, Default access point, Public user name, Use compression, Registration, Use security, Proxy Server, and Registrar Server. We'll going through each of these and configure the two submenus: Proxy Server and Registrar Server.







**Profile name:** Anything you want. I called mine "Business Line"
**Service profile:** _IETF
**Default access point:** Select either a wifi connection or 3G connection. In my case I'm selecting "Rogers Internet"
**Public user name:** _sip:leifmadsen_cell@pbx.my_asterisk_box.com_ (notice how leifmadsen_cell is the same as what we configured in sip.conf)
**Use compression:** _No
**Registration:** _Always on_ (you can set this to 'When needed' if you only want to place outbound calls via VoIP sometimes)
**Use security:** _No___







**Proxy Server >
**Proxy server address:** _pbx.my_asterisk_box.com
**Realm:** _pbx.my_asterisk_box.com
**Username:** _leifmadsen_cell
**Password:** _super_secret_password
**Allow loose routing:** _Yes
**Transport type:** _UDP
**Port:** _5060_ (unless you've changed this yourself on your Asterisk box)______**







**Back > Registrar server >
(fill this information out exactly like the Proxy server section)**







At this point, hit the **Back** button a couple of times to make sure you phone will register. If you're still having issues, double check all your configuration options, and potentially restart the phone. With older firmware versions I've had issues where if I don't get it perfect the first time and make a change, I have to restart the phone.







Once we see that we've registered the device, we need to enable it from another screen so that we can place and receive calls from Asterisk.







Go back out of the SIP Settings screen to your Connection screen in the Tools menu, then select Internet tel.







By default you will see a screen that says (no Internet telephone settings).







Select the Options button and create a new profile. There will be two fields: Name and SIP profiles. By default the SIP profile field should be selected with Business Line (or whatever you called your SIP connection) automatically. The Name field is currently set to Default, but I just renamed it to VoIP. Feel free to name it anything you want.







Back out of all your menus until you get back to the main screen. You should see an icon in the upper-right hand corner that looks like a telephone hand set on top of a globe. At this point, try dialing one of the extensions on your Asterisk server to see if things are working! I like to try calling my voicemail as it lets me test DTMF as well.







Below is a (modified) INVITE from the E71 showing what you'll see when the request comes from the phone. The most interesting part is the SDP portion which shows us which codecs the device supports and offers. In the case of the phone and firmware combination I'm using, I can use G.711 ulaw and alaw, G729, and iLBC.



    
    INVITE sip:8500@pbx.my_asterisk_server.com;user=phone SIP/2.0
    Route:
    Via: SIP/2.0/UDP 10.10.10.84:5060;branch=z9hG4bKlq60dckmalhc6vap06nosen;rport
    From: ;tag=mh5gdciapphc6m6506no
    To:
    Contact:
    Supported: 100rel,sec-agree
    CSeq: 1252 INVITE
    Call-ID: rdw6Iy8zoIfKxg6LzJ7FSPdgBvIb8y
    Allow: INVITE,ACK,BYE,CANCEL,REFER,NOTIFY,OPTIONS,PRACK
    Expires: 120
    Privacy: none
    User-Agent: E71-2 RM-346 400.21.013
    P-Preferred-Identity: sip:leifmadsen_cell@pbx.my_asterisk_server.com
    Max-Forwards: 70
    Content-Type: application/sdp
    Accept: application/sdp
    Content-Length: 447
    
    v=0
    o=Nokia-SIPUA 63437257072703500 63437257072703500 IN IP4 10.10.10.84
    s=-
    c=IN IP4 10.10.10.84
    t=0 0
    m=audio 49152 RTP/AVP 96 0 8 97 18 98 13
    a=sendrecv
    a=ptime:20
    a=maxptime:200
    a=fmtp:96 mode-change-neighbor=1
    a=fmtp:18 annexb=no
    a=fmtp:98 0-15
    a=rtpmap:96 AMR/8000/1
    a=rtpmap:0 PCMU/8000/1
    a=rtpmap:8 PCMA/8000/1
    a=rtpmap:97 iLBC/8000/1
    a=rtpmap:18 G729/8000/1
    a=rtpmap:98 telephone-event/8000/1
    a=rtpmap:13 CN/8000/1


So beyond that, there shouldn't be anything else you need to do. Using the same configuration in sip.conf for Asterisk should also work with Fring. Perhaps I'll create another blog post in the future about using Fring with E71 if there is interest in that. Anyone who wants to try testing out some video calls through my Asterisk box using their Fring video enabled phone, just let me know offline and we'll set something up!
