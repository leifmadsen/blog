---
author: leifmadsen
comments: true
date: 2011-08-29 20:27:03+00:00
layout: post
slug: asterisk-10-asterisk-1-hh10
title: Asterisk 10 == Asterisk 1.^H^H10
wordpress_id: 364
categories:
- Asterisk
tags:
- asterisk 10
- information
- public service announcement
- versioning
---

In case you missed it, the next version of Asterisk is now in beta, and at the same time, has undergone a minor version numbering scheme. As it is unlikely that Asterisk will ever have a 2.0 release since for years now, that has generally meant Asterisk would undergo a major underlying change in both how it was programmed and the user experience (and since it would be a major disruption to the Asterisk community), it was deemed unnecessary to utilize the 1. preamble in front of the version numbers.

Asterisk versioning has used the following as branch numbers over the years:



	
  * 1.0

	
  * 1.2

	
  * 1.4

	
  * 1.6.0

	
  * 1.6.1

	
  * 1.6.2

	
  * 1.8


The next version to have followed Asterisk 1.8 would have been Asterisk 1.10. Since it has been determined the prefix of _1._ is now superfluous, it was simply dropped. So instead of the version following 1.8 being:



	
  * 1.8

	
  * 1.10


We now have...

	
  * 1.8

	
  * 10


This should hopefully lead to a slightly less confusing numbering scheme going forward as there will no longer be the skipped odd numbers. Kevin Fleming at Digium explains the reasons for dropping the leading 'one dot' in his blog post at [http://blogs.digium.com/2011/07/21/the-evolution-of-asterisk-or-how-we-arrived-at-asterisk-10/](http://blogs.digium.com/2011/07/21/the-evolution-of-asterisk-or-how-we-arrived-at-asterisk-10/)

As Asterisk moves forward, this is how versions will look:

Asterisk branch versions (which signify major version increases) will increment singularly:



	
  * 10

	
  * 11

	
  * 12


Within each of those branches minor versions will be released for the time the branch is supported. (Information about the support level of Asterisk branches is available at [https://wiki.asterisk.org/wiki/display/AST/Asterisk+Versions](https://wiki.asterisk.org/wiki/display/AST/Asterisk+Versions).) These would be the bug fixes that an Asterisk implementer/administrator would deploy. Some examples include:



	
  * 10.0.0

	
  * 10.1.0

	
  * 10.2.0

	
  * 10.3.0

	
  * 10.4.0


You'll have noticed the implicit declaration of the 'dot zero' on the end of the version. In the past when a security release or regression is resolved for a tag, an additional version number is added to the end. Lets take Asterisk 10.2.0 as an example of a version that was to receive a change to the tag after initial release, perhaps for a security update. Instead of requiring administrators to update to a tag of Asterisk that has changes in addition to the security changes, a new tag with only the changes required to satisfy the resolution of the security issue are added.

(The mechanics of which are essentially to copy the existing tag to a new tag number, merge the changes, then repackage the new tag. The equivalent of copying the contents of one directory to another new directory, and making a single change.)

So for a security issue being resolved in Asterisk 10.2.0, there would be a release of Asterisk 10.2.1. If additional changes were made to the base tag of 10.2.0, then you would see:

	
  * 10.2.0

	
  * 10.2.1

	
  * 10.2.2


Only spot testing should be required for upgrades between 10.2.0 -> 10.2.1 -> 10.2.2. Of course more thorough testing between something like 10.2.0 and 10.3.0 would be required by the administrator.

Hopefully this helps alleviate any remaining confusion.
