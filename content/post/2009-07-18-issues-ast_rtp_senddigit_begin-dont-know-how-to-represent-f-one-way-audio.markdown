---
author: leifmadsen
comments: true
date: 2009-07-18 15:18:28+00:00
layout: post
slug: issues-ast_rtp_senddigit_begin-dont-know-how-to-represent-f-one-way-audio
title: 'Issues: ast_rtp_senddigit_begin: Don''t know how to represent ''f'' (one way
  audio)'
wordpress_id: 86
categories:
- Asterisk
tags:
- Asterisk
- issues
- one way audio
- wanpipe
---

I keep seeing questions like this recently on the mailing list and in the #asterisk IRC channel.

"ast_rtp_senddigit_begin: Don't know how to represent 'f'   shows up on the console then I get one way audio...   * 1.4.25.1, wanpipe 3.3.15.20, zaptel 1.4.12.1, libpri 1.4.7.... any suggestions?"

I forget who originally said how to fix it (it was in a mailing list thread that I can't find right now...), but basically the answer to resolve it was to disable the DTMF detection in the wanpipe driver. Seems it is picking up tones or artifacts in the audio path, and thinking a fax tone was detected. This is causing one way audio at random intervals.

Hope that helps someone!
