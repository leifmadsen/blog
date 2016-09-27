+++
categories = ['Linux', 'Console', 'Unixporn']
date = "2016-09-27T16:11:17-04:00"
description = ""
keywords = ["linux","console","terminal","oldschool"]
title = "A Console Obsession"

+++

# It's A Console Thing
Recently I've gotten into running as many of my day-to-day applications in a
Linux console. Thought I'd briefly share the applications I've been playing
with.

* **GerTTY** (http://gertty.readthedocs.io/en/master/): Synchronize and follow
  Gerrit-hosted projects, and perform code reviews. It's a bit slow, but
  generally works pretty well once you get over the initial sync.

    _More Info_: https://major.io/2016/05/11/getting-started-gertty/

* **Weechat** (https://weechat.org/): IRC client with tiling-window manager like
  options. Can split the window into various buffers in either horizontal or
  vertical arrangements. Deals with multiple servers, and provides many
  plugins.

    _More Info_: http://benoliver999.com/2014/02/18/weechatconf/

* **Profanity.IM** (http://profanity.im/): XMPP client using libstrophe and ncurses
  for an IRSSI (see Weechat...) like interface. I'm using this to connect to
  the Slack XMPP gateway.

    I had to build the project myself since there is no native RPM for Fedora.
    This meant I had to also compile libstrophe and get that all installed in the
    right location to make it available for Profanity. Not sure why, but I could
    never get Profanity to find it in `/usr/local/lib` so I gave up and installed
    libstrophe in `/usr/lib64` and all was well.

    _More Info_: http://nochair.net/posts/2015/11-09-linux-messaging.html

* **NeoMutt** (http://www.neomutt.org/): Email application that I got working with
  my works (Red Hat) Google Apps service. So far I'm a rookie when it comes to
  using Mutt, but I've been reading and slowly learning some of the keys. The
  sidebar certainly helps. I had to map some custom stuff to move around the
  sidebar comfortable, but that wasn't a big deal.

    _More Info_: https://hobo.house/2016/08/08/switching-from-mutt-to-neomutt/

* **OfflineIMAP** (http://www.offlineimap.org/): I'm currently writing this while
  waiting for all my email to sync offline (OMG there is so much...), so I
  don't even have it fully integrated yet. OfflineIMAP is an application that
  I'll integrate with NeoMutt so I can have offline email.

    I don't really travel a lot, but I've been told using this along with notmuch
    makes searching for emails really powerful.

    _More Info_: http://stevelosh.com/blog/2012/10/the-homely-mutt/

* **Notmuch** (https://notmuchmail.org/): A powerful tag-based email search system.
  I haven't even set this up yet, so I have no idea what I'm doing here :)
