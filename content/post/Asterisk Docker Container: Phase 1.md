+++
categories = ["asterisk","docker","rpm","automation"]
date = "2015-11-10T19:41:55-05:00"
description = ""
keywords = ["asterisk","docker","rpms","automation"]
title = "Asterisk Docker Container: Phase 1"

+++
At AstriCon 2015 this year, there was a lot (and I mean a lot) of discussion around microservices (Docker), 
and what items are required over the next year by the development community in order to make Asterisk better 
suited to running in that environment.

One of the first things is, clearly, to have a container image that Asterisk runs in. I've done this a 
few times now, but having something that can be passed over to the official Asterisk Git repository, 
and which everyone can contribute to, utilize and play with would be the goal here. The community is 
already pretty fragmented, and there are a bunch of useful, but unofficial images, and I don't think 
any of them have become the defacto image.

Part of the problem is really around packages. Digium does release some official Asterisk packages, but 
it's not automated. Another interesting tidbit that came out of AstriDevCon is that no one really uses packages.

Let me elaborate on what I mean by that. Everyone seems to want packages of the project. The issue seems 
to be that anyone using packages probably already has access to them through their distribution. If they 
don't want or can't use those packages, then they are likely using some sort of custom deployment, in 
which case they are probably compiling Asterisk onto the box in question, along with their custom patches.

We need to figure out an easier way for people to have access to custom packages.

With that in mind, we also want people to have access to an Asterisk container image that they can use, 
but with the ability to rebuild it locally if need be, without having to setup a ton of infrastructure to 
do it.
