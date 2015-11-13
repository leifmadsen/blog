---
author: leifmadsen
comments: true
date: 2012-07-19 15:03:05+00:00
layout: post
slug: linux-creating-files-named-1-everywhere
title: bash creating files named '1' everywhere!
wordpress_id: 452
categories:
- Musings
- Programming
tags:
- bash
- bashrc
- redirects
- ssh-add
---

So I ran into something kind of stupid today :)  Adding a little note for anyone who might run into a similar instance.

I have some `ssh-add` stuff that gets run in my `.bashrc` file, but when I was outputting it, I was doing:

```
ssh-add ~/.ssh/some_key > /dev/null 2&>1
```

Note the `2&>1` at the end. That means to redirect output to a file named 1. You need to flip the `&>` into `>&`, so the fixed version looks like:

```
ssh-add ~/.ssh/some_key > /dev/null 2>&1
```
