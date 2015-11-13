---
author: leifmadsen
comments: true
date: 2011-12-22 14:39:07+00:00
layout: post
slug: bashrc-trick-for-git
title: .bashrc trick for git repo and branch information
wordpress_id: 404
categories:
- Technology
- Useful Tools
tags:
- bash
- bashrc
- custom
- git
- prompt
- ps1
- tricks
---

The other day I was talking to my friend [Russell Bryant](http://russellbryant.net) who pointed me to some .bashrc magic that would show me which branch I was currently working with inside a git repo on my system. I found it incredibly handy and have modified the ANSI colour coding slightly.

```bash
export PS1='[\u@\h \[33[0;36m\]\W$(__git_ps1 "\[33[0m\]\[33[0;33m\](%s)")\[33[0m\]]\$ '
```

On Fedora Russell mentioned that you need the `bash-completion` installed. We're unsure if you need anything on other distributions.

> Edit: January 6, 2012_
> As I'm using my laptop today, I modified the .bashrc file on Ubuntu 10.04, and here is the PS1 code I came up with. It's nearly the same, but I'm using bold today instead of the unbolded colours of lore.

```bash
PS1='${debian_chroot:+($debian_chroot)}\[\033[28;01m\]\u@\h\[\033[00m\]:\[\033[1;36m\]\W$(__git_ps1 "\[\033[00m\]\[\033[1;33m\](%s)")\[\033[00m\]\$ '
```
