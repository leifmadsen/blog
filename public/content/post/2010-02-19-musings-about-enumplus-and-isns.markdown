---
author: leifmadsen
comments: true
date: 2010-02-19 15:38:07+00:00
layout: post
slug: musings-about-enumplus-and-isns
title: Musings about ENUMplus and ISNs
wordpress_id: 168
categories:
- Asterisk
- Musings
tags:
- Asterisk
- dialplan
- enum
- isn
- services
- sip
- SIP URI
- URI
---

Recently I've been playing around with a couple of technologies that I haven't used in quite a while; ENUM and ISN. First, a little information on what these technologies are about.


## ISNs and ITADs


First, lets talk about ISN (ITAD Subscriber Number) and ITAD (Internet Telephony Administrative Domain). I think the http://www.freenum.org website does a good job of succinctly describing the problem attempting to be addressed:

"The Freenum/ISN system is 12-digit-keypad (telephone handset) friendly method of providing mapping between users. While the eventual use of email-style URI pointers is the eventual goal for communications identifiers, it is still the case that the majority of the world's telephony users are trapped using a 12-digit keypad for extended numeric entry, and it is for the purposes of these devices that the Freenum system and ISN dialing was designed as a "stopgap" which may last many years. Using ENUM-like methods and IETF standards but not using telephone numbers, the Freenum/ISN dialing system is designed to initially allow SIP-capable proxies and iPBX systems to connect to each other in a free, open, and protocol agnostic manner over the Internet. Initially focused on SIP voice communications, the platform is hoped to eventually extend to other communications methods as those protocols become more widespread." -- freenum.org

An ISN is a number that looks like:  100*460

The ITAD part of that ISN is the number 460 where you can think of the 460 as the domain. If we used an email address (or SIP URI for that matter) as an example, we'd have something like leif@leifmadsen.com where leifmadsen.com would be the domain, and the number 460 would be the equivalent of that. The number 100 would be the unique identifier within that domain, which would represent 'leif' prior to the email 'at' symbol. And finally, you can think of the asterisk in the ISN as the 'at' symbol (@) in the ISN. We could then read 100*460 as "extension 100 at ITAD 460". And the 100*460 would then map to the SIP URI of sip:leif@leifmadsen.com (for example).

This allows a stopgap measure of permitting traditional telephony devices to dial VoIP addresses from their keypad. Because of the nature of VoIP and how a simple URI can actually ring multiple devices, enter into a queue, or an auto-attendant, it doesn't always make sense to utilize a telephone number to represent a SIP URI (see more information about this below in the ENUM section). Perhaps you are a small company with approximately 20 devices, but only 2-3 phone numbers. It doesn't make sense to obtain multiple phone numbers for your company just as a method of dialing a SIP URI from a traditional keypad. In this way, you can assign numbers any which way it makes sense in your company with ISNs.

The company with 20 extensions could then assign ISNs to each device such as:  201*460, 202*460 ... 220*460. The operator could be 0*460, and perhaps the auto-attendant could be 1*460. There are no set mechanisms or best practices (yet), but as time evolves, perhaps these will come to fruition.

I'm not sure if ISNs will catch on with the general public, as historically things like ENUM and other services of this nature haven't progressed as much as they likely should, but the idea is sound, and certainly makes more sense to me than having to remember several phone numbers for each extension or location.

As this is simply an overview about ISNs, I'll stop here. Future articles will delve into the configurations and testing for outbound and inbound calls with Asterisk, setting up DNS, etc. For now, see the http://freenum.org website for more information about configuring these aspects. Unfortunately the Asterisk information is out of date (in terms of utilizing the best features of the dialplan). I'd be happy to update the information if enough requests and interest is generated.


## ENUMplus


ENUMplus (http://www.enumplus.org) is a site which takes the information from several ENUM databases and allows you to perform a single lookup using cURL. Since there is a lot of technology going on in that sentence, lets step back and define each of these aspects.

I think the wikipedia entry about ENUM does more justice about what it is than what I could do, so lets quote a resource :)

"**Telephone number mapping** is the process of unifying the [telephone](/wiki/Telephone) number system of the [public switched telephone network](/wiki/Public_switched_telephone_network) with the [Internet](/wiki/Internet) addressing and identification [name spaces](/wiki/Name_space). Telephone numbers are systematically organized in the [E.164](/wiki/E.164) standard, while the Internet uses the [Domain Name System](/wiki/Domain_Name_System) for linking [domain names](/wiki/Domain_name) to [IP addresses](/wiki/IP_address) and other resource information. Telephone number mapping systems provide facilities to determine applicable Internet communications servers responsible for servicing a given telephone number by simple lookups in the Domain Name System.

The most prominent facility for telephone number mapping is the E.164 NUmber Mapping (ENUM) standard. It uses special [DNS record](/wiki/DNS_record) types to translate a telephone number into a [Uniform Resource Identifier](/wiki/Uniform_Resource_Identifier) or IP address that can be used in Internet communications." -- wikipedia entry at http://en.wikipedia.org/wiki/Telephone_Number_Mapping

And cURL is a technology that allows you place a request via a website, and have information returned. It is most typically used by programmers to get information from a website without having to parse through the entire site.

So by marrying these two technologies, ENUM and cURL together, ENUMplus has created a one-stop-shop for performing ENUM lookups. By performing an ENUM lookup prior to placing a call from your Asterisk system, is that if a telephone number has been registered with one of the ENUM organizations and has a SIP URI to point to, then we can utilize that SIP URI instead of calling over the PSTN, which can save toll costs, and free up a circuit for other calls.

I originally wrote a section of dialplan while testing out the service (which is very quick!) and added it to the ENUMplus wiki page for the configuration of Asterisk 1.6 systems. Originally I had this done as a separate path for dialing that would utilize a prefix of 7 prior to dialing out in order to do an ENUM lookup, and then you could dial without the prefix if you didn't want the lookup (or if the lookup failed). I've since realized that this method is the wrong approach for obvious reasons (who wants to dial the number twice?), so I have since modified my dialplan to always utilize ENUM lookups prior to placing a call via the PSTN.

I want to show you the following example from my dialplan, which I'll eventually clean up and add to the ENUMplus wiki.

```
exten => _+1NXXNXXXXXX,1,Set(X=${EXTEN:1})
exten => _+1NXXNXXXXXX,n,Goto(setCID,1)
exten => _+NXXNXXXXXX,1,Set(X=1${EXTEN:1})
exten => _+NXXNXXXXXX,n,Goto(setCID,1)
exten => _1NXXNXXXXXX,1,Set(X=${EXTEN})
exten => _1NXXNXXXXXX,n,Goto(setCID,1)
exten => _NXXNXXXXXX,1,Goto(1${EXTEN},1)

exten => setCID,1,NoOp()
exten => setCID,n,Set(CALLERID(name)=LM Enterprises)
exten => setCID,n,Set(CALLERID(num)=4164790259)
exten => setCID,n,Goto(lookup,1)

exten => lookup,1,Verbose(2,Looking up direct dial via ENUM from ENUMPlus: ${X:1})
exten => lookup,n,Playback(silence/1&doing-enum-lookup)
exten => lookup,n,Set(CURL_RESULT=${CURL(${GLOBAL(G_ENUMPLUS_API)}/${X:1},key=${GLOBAL(G_ENUMPLUS_KEY)})})
exten => lookup,n,GotoIf($[${ISNULL(${CURL_RESULT})}]?no_result,1)
exten => lookup,n,Goto(dial,1)

exten => dial,1,Verbose(2,Lookup returned:  ${CURL_RESULT})
exten => dial,n,Playback(enum-lookup-successful)
exten => dial,n,Dial(${CUT(CURL_RESULT,|,1)},30)
exten => dial,n,Hangup()

exten => no_result,1,Verbose(2,ENUMPlus returned no data.)
exten => no_result,n,Playback(silence/1&enum-lookup-failed)
exten => no_result,n,Set(OUTBOUND_ROUTE=SIP/${DEFAULT_ITSP_ROUTE})
exten => no_result,n,Dial(${OUTBOUND_ROUTE}/${X})
exten => no_result,n,Hangup()
```
