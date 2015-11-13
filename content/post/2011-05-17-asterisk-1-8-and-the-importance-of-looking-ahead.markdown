---
author: leifmadsen
comments: true
date: 2011-05-17 20:40:55+00:00
layout: post
slug: asterisk-1-8-and-the-importance-of-looking-ahead
title: Asterisk 1.8 And The Importance Of Looking Ahead
wordpress_id: 326
categories:
- Asterisk
- Musings
tags:
- '1.8'
- Asterisk
- community
- development
- lts
- maintenance
- releases
- testing framework
---

With the end of maintenance for the Asterisk 1.4 (the previous long term support (LTS) release) and Asterisk 1.6.2 (the previous standard, short term support release) branches, the time to look at using Asterisk 1.8 (the next long term support release, which provides another 4 years of maintenance, followed by a year of security support) is upon us. For those who have successful deployments of Asterisk 1.4 and 1.6.2 (heck, even 1.2!) there is no immediate need to migrate those existing systems; let them happily continue what they’re doing. And for those who have successful product launches based around 1.4 and 1.6.2, there is still a year of security maintenance, so the lead time to migrating existing systems to 1.8 can start now, but doesn't need to happen for another 12 months, which gives us all a little breathing room.

It is important that the Asterisk community continue to look forward and progress the Asterisk project. The resources of the Asterisk Development community must be used as effectively as possible, and sometimes this means making tough decisions in the short-term for the greatest benefit in the long term. With the end of maintenance support after the releases of Asterisk 1.4.42 and 1.6.2.19 (with the first release candidates due out shortly), all focus can now be put onto Asterisk 1.8, continuing to stabilize additional components and making it the most robust, feature rich release of Asterisk to date.

I've already deployed numerous systems on Asterisk 1.8, and have been ecstatic as to the early reliability compared to other dot-zero releases. I've always been an early adopter when it came to Asterisk though, and I can certainly say the number of show-stopping issues I've run into has continued to decrease excessively over the years. When deploying Asterisk 1.4 pre-1.4.0, I was working on a database driven, physically distributed call centre where I learned many of the tricks of my trade. When I deployed another call centre running pre-1.6.2.0, I found it remarkably stable in comparison to those early 1.4 deployments (and that call centre is STILL running pre-1.6.2.0 code without issue).

Having done a few more deployments with pre-Asterisk 1.8.0  (and subsequently 1.8.2 and 1.8.3 based deployments), I've run into even less issues, and none of them show stoppers. I think a few things contribute to those successful deployments:




	
  * Enhanced understanding of Asterisk after dozens of custom installations

	
  * Development of best-practices in many areas of Asterisk

	
  * [Reviewboard](https://reviewboard.asterisk.org) which finds many issues in code BEFORE they are committed, rather than when doing deployments

	
  * Developers having greater experience with the Asterisk code base and knowing how best to code in various situations -- greater code fu



One of my favourite new things is the [Asterisk Testing Framework](http://bamboo.asterisk.org), currently being managed by Paul Belanger. The testing framework allows people to provide tests to the project in order to have greater confidence in performing upgrades going forward. So if there are some business critical aspects to your deployments, and you want to be confident that code changes don't break your infrastructure, then spend the time writing tests and submitting them to the project. Not only will you be helping to make Asterisk better, you'll be getting the direct advantage of having the developers notified of changes to functionality shortly after a commit.

More information about where Asterisk is going into the future was posted by Bryan M. Johns on the Digium blog: [http://blogs.digium.com/2011/05/03/the-importance-of-looking-ahead/](http://blogs.digium.com/2011/05/03/the-importance-of-looking-ahead/)
