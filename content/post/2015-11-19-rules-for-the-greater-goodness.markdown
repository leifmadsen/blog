+++
categories = ["development","product","rules","list"]
date = "2015-11-19T10:21:26-05:00"
description = ""
keywords = []
title = "Rules For The Greater Goodness; A Product Development Guide"

+++

This page documents and provides bullets about the way to approach (or avoid)
building products. These are lessons we've learned from previous encounters and
which we wish to avoid in the future. By sticking firmly to these development
rules, we avoid getting bogged down in complete system rearchitectures in the
future. The means to a scaled end is to approach the first customer as all your
customers.
<!--more-->

# Rules For The Greater Goodness ## A Product Development Guide
1. **Java is strictly forbidden** from any client or server side applications
being built or interacted with. Applications utilizing Java may be used in
limited usage when warranted.
  * For example, Confluence, our documentation system utilized Java, but no
    customer interactions are had via Java, and no core systems utilize Java.
1. **Rube-Goldberg mechanisms are strictly forbidden.** Build simpler, more
elegant solutions that scale, are documented, and utilize best practices.
1. Utilize development tools and languages that speak to the strengths of the
system being built. Prefer using languages already in use. Have a primary
development language.
1. If you can interact with an **API**, do it. If you need to expose data to
another subsystem, front it with an API.
1. Love documentation. Be one with documentation. **Document** your code for
the next fool that needs to work on it. It's probably going to be you.
1. **Automate everything** you can so you can spend time building new
functionality.
1. Build in as much **redundancy** and automatic **failover** as possible.
Capture errors in sane manners. The focus is to build systems that require very
little support. Support costs money.
1. If you have a choice between a pre-paid solution and an open source
solution, but the open source solution requires more effort, it doesn't matter.
**Use open source software.**
   * **Avoid vendor lock** in at all costs. It costs!
1. **Load testing** is paramount, and realistic load testing even more so.  If
you don't know the loads at which your application will break you can't know
what customer experiences will be like.
  * If you don't know the expected load, how do you expect to monitor it? How
    will you know what your thresholds are for warning and critical alarms?
1. **Monitor** your network and applications. Understand what they are doing.
1. **Log your data.** Log your network traffic, your application logs, and your
API interactions. Provide a simple interface for gathering data. Don't rely on
trying to reproduce issue after the fact.
1. **Have style.** When possible write a style guide for what you're building.
Keeping things clean will produce better code in the future. If your code is
pretty and conforms to code guidelines you're less likely to hack and slash.
Follow the style guides.
1. **Contribute.** Using open-source projects is a two-way street. Any
contributions we can make back to the community helps both the project and us.
1. **Normalize** your database tables. Database creation should strive towards
fifth normal form (5NF). See [Fifth Normal
Form](http://en.wikipedia.org/wiki/Fifth_normal_form)
1. **Control the applications.** Don't deploy applications to clients that you
can't control and upgrade. Subscribing to a hosted mentality is that you have a
single application for all clients. Own this and everyone will benefit from the
same platform.
1. **Limit Customization.** If you're going to build the functionality for a
client, make sure the time you're spending is helping the greater good.
Architect and develop features requested by clients in such a way that they are
generic and help the greater community (your client base).
  * Small customizations derail your forward momentum and take you on tangents.
1. **Sell what you have.** Don't sell what the customer wants and lock yourself
into having to build functionality in a rush. Sell the merits of the platform
to the customer and help them understand why a customization for them hurts
other customers on the platform, and that you don't want to hurt your
customers; including them. See 15 and 16.
1. **User experience** is paramount. It should be well researched and designed
with ease-of-use in mind. Engineers should never try to directly implement UX
concepts; well-designed software should always be abstracted from design
elements.
1. **Set reasonable and hard limits** for expectations of the platform. Don't
allow the platform or any of its features to be misrepresented or misconstrued.
See 17.
1. **Constant innovation** is imperative to the success of the platform. No one
wants old technology and all technology becomes obsolete almost immediately.
1. **Never ignore customer feedback!** Even if it's not feasible to implement a
customer's request, the request is generally always coming from an actual
use-case.
1. **Examine and understand use-cases.** Always make sure the use-case is
understood so that a proper solution can be implemented.
