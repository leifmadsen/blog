---
author: leifmadsen
comments: true
date: 2009-06-17 01:24:07+00:00
layout: post
slug: new-articles-coming-soon
title: New articles coming soon!
wordpress_id: 32
categories:
- Asterisk
- Musings
tags:
- AgentCallbackLogin()
- agents
- Asterisk
- asterisk book
- dialplan
- queue
- TFoT
---

I have vowed to try and write at least ONE article per week on my blog, even if it is quite short. I'm not sure I will be able to get to write an article this week due to some pressing consulting issues, but I'm still gonna try. If anything, I'm going to cheat and say this is my post for *this* week. How about I make a rule that says I can only cheat once per month? :)

I wanted to let you know I have a couple of articles lined up for later this week and next week. They will deal with Asterisk Queue()'s as that is the area I have been spending the most time lately. They include:




	
  * Moving from the deprecated AgentCallbackLogin() application to a dialplan based solution

	
  * A series of articles (4-5 articles) on building a single system, hot-desking Agent queue system

	
  * The first draft of a complete re-write of chapter 3 of Asterisk: The Future of Telephony



The first bullet point is an issue I have been seeing on IRC and other forums for about 2 years, and which I want to solve by providing the necessary documentation on how to move from using AgentCallbackLogin() to a dialplan based solution as is the preferred method. I will create a dialplan subroutine which will hopefully make it easy to replace the calls to AgentCallbackLogin() with a GoSub().

The second bullet point is something I'm very excited about. I recently build a hot-desking solution for a client, and while building it was able to keep it quite general and didn't need to add anything that wouldn't be useful for the general population. I have received permission from the client (who will remain nameless for now) to utilize the configuration files I built for them in a series of articles detailing how to build the system from scratch. It is a win-win situation because you get to learn how I built the system, and they get some additional documentation on how the system works, and why things were built the way they were.

The third bullet point is a good deal amount of work, which is really just the start of a greater amount of work; the updating of Asterisk: The Future of Telephony, 2nd Edition, to a 3rd edition that covers the 1.6 series of Asterisk. I have recently gotten enough exposure to working with Asterisk 1.6 releases that I'm confident in being able to start on this grandiose project. I plan on using this blog as a test bed for some draft work.

So stay tuned for some exciting articles over the coming 2-3 weeks!
