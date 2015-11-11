---
author: leifmadsen
comments: true
date: 2011-02-18 17:08:50+00:00
layout: post
slug: first-hd-conference-in-asterisk
title: First HD Conference In Asterisk!
wordpress_id: 283
categories:
- Asterisk
tags:
- Asterisk
- ConfBridge
- conferencing
- g722
- HD
- wideband
---

Today Russell Bryant and I had the first public HD conference using Asterisk! There had been other testing done by Malcolm Davenport and David Vossel (who is the developer working on this integration) internally, but this was the first public HD enabled conference using Asterisk (as far as I'm aware).

It worked really well! People were able to join in, and those who were calling in via G722 were able to hear each other in wideband, while the other people in the conference who were using narrowband codecs like GSM and ulaw didn't hear any difference in the audio from the participants. It's very cool that just because someone joins in a narrowband codec that it doesn't bring the quality of the audio down for all participants. Very nice!

This is a feature that is slated to be in Asterisk 1.10, and it's comforting to know just how well this works already. You can check out the team branch where David Vossel is working at http://svn.asterisk.org/svn/asterisk/team/dvossel/fixtheworld_phase2

Enjoy!
