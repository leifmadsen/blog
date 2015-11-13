---
author: leifmadsen
comments: true
date: 2012-01-16 13:28:10+00:00
layout: post
slug: converting-multiple-exten-lines-to-using-same-in-asterisk-dialplan
title: Converting multiple exten => lines to using same => in Asterisk dialplan
wordpress_id: 436
categories:
- Asterisk
- Programming
tags:
- Asterisk
- dialplan
- exten =&gt;
- pattern match
- regex
- regular expressions
- same =&gt;
---

Last week I wanted to start changing some 1.4 based Asterisk dialplan to a 1.8 based Asterisk system, and in that process wanted to convert lines like:

```
exten => _NXXNXXXXXX,1,NoOp()
exten => _NXXNXXXXXX,2,GotoIf($[...]?reject,1)
exten => _NXXNXXXXXX,3,Dial(SIP/foo/${EXTEN})
...
```

into using the same => prefix:

```
exten => _NXXNXXXXXX,1,NoOp()
 same => n,GotoIf($[...]?reject,1)
 same => n,Dial(SIP/foo/${EXTEN})
```

In order to do that, [Mike King](https://twitter.com/#!/mikemking) helped me out with the following regular expressing which I used in vim:

```
%s/exten\s*=>\s*[^,]\+,\s*[n2-9]/ same => n/g
```
