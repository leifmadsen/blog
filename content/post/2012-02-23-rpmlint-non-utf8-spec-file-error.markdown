---
author: leifmadsen
comments: true
date: 2012-02-23 18:43:54+00:00
layout: post
slug: rpmlint-non-utf8-spec-file-error
title: rpmlint non-utf8-spec-file error
wordpress_id: 440
categories:
- Useful Tools
tags:
- bash
- iconv
- rpm
- rpmlint
- utf8
---

I've been doing a bunch of work with RPMs lately, and while running rpmlint against a spec file I was modifying, I received this error:

```bash
myfile.spec: E: non-utf8-spec-file myfile.spec
```

After Googling, I ran into a way of finding the non-compliant characters.

```bash
$ iconv -f ISO-8859-8 -t UTF-8 myfile.spec > converted.spec
$ diff -u myfile.spec converted.spec
```

(Answer thanks to Dominique Leuenberger @ [http://lists.opensuse.org/opensuse-packaging/2011-04/msg00005.html](http://lists.opensuse.org/opensuse-packaging/2011-04/msg00005.html))
