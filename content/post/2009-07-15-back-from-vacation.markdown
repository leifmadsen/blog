---
author: leifmadsen
comments: true
date: 2009-07-15 17:36:51+00:00
layout: post
slug: back-from-vacation
title: Back from Vacation!
wordpress_id: 45
categories:
- Asterisk
- Musings
tags:
- news
- update
---

Just a quick note letting you know I'm back from vacation! Just been working on catching up on a few things, and have started working on a new article. It will be focusing on how to convert from using AgentCallbackLogin() to using the AddQueueMember() method of dynamically adding members to queues. Since AgentCallbackLogin() has been removed from Asterisk 1.6.0 and beyond, you'll need to use the AddQueueMember() method.

Luckily, all the tools we need to use it on Asterisk 1.4 are available for us, so the article will look at doing it on Asterisk 1.4 so you can get comfortable using that method before upgrading to Asterisk 1.6.0 (and beyond) if you need some of the new features. Some people have not been able to upgrade to Asterisk 1.6.0 due to the need for AgentCallbackLogin(), and have not had a chance to create the dialplans necessary.

The article will probably be called something like, "Migrating from AgentCallbackLogin() to standard dialplan methods". I hope to have a draft out later today or tomorrow!
