---
author: leifmadsen
comments: true
date: 2010-09-20 15:37:44+00:00
layout: post
slug: asterisk-imap-and-gmail
title: Asterisk IMAP and Gmail
wordpress_id: 221
categories:
- Asterisk
tags:
- Asterisk
- email
- gmail
- google
- howto
- imap
- ssl
- voicemail
---

Today I was working on the next edition of the Asterisk book and wanted to see if I could get Asterisk IMAP voicemail support to work with Gmail. I had tried doing this a few times in the past without success, but since I had spent some time documenting and testing against Dovecot last week for another client and gotten everything working, I figured I had a good base to start trying to connect to the Gmail IMAP servers.

At first I was having problems with getting Asterisk to connect to the server as it would keep timing out when trying to connect to the Gmail IMAP servers on port 993. I looked at the instructions for connecting and double checked, and I thought I had everything right. I also made sure my IMAP library was compiled with OpenSSL support since Gmail requires you to connect via SSL.

After reading a few emails and doing more testing, I finally stumbled upon the missing link! Find below the snippet of voicemail.conf configuration that finally allowed me to connect to the Gmail IMAP system with Asterisk IMAP voicemail support.

Note: Be aware that there is a mixture of commas and pipes in the line where we've setup mailbox 100. This is not a typo!

```
; voicemail.conf
imapserver=imap.gmail.com
imapport=993
imapflags=ssl

pollmailboxes=yes
pollfreq=30

[default]
100 => 100,Leif Madsen,,,attach=no|imapuser=leif.madsen@MYDOMAIN_GOOGLE_APPS.com|imappassword=my_secret_password
```

I was using this with Google Apps for one of the domains we bought for working on the book, so the login is the full email address. The password is what you use for logging into the Gmail interface. Also, you need to make sure you've enabled IMAP support in the web interface before trying this or else your connection won't work.

More information including step-by-step instructions on compiling IMAP support into Asterisk and configuration examples for Dovecot and Gmail will be in the upcoming book, but I was so excited to get this working today that I thought I'd share the secret sauce at least so you don't have to wait for the whole recipe.

Connecting to Gmail was not as quick as connecting to Dovecot on a remote server I was working with. I imagine this is due to the high load Google has to deal with, so while it works, there may be some minor delays when retrieving and leaving voice messages, but nothing that caused it to be unusable.

Note: The KEY to making it work was the `imapflags=ssl` part. Without that you won't get connected and will have problems with timeouts and such going on with Asterisk. Once I enabled the `ssl` flag I was golden.
