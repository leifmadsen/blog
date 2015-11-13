---
author: leifmadsen
comments: true
date: 2015-09-09 21:20:40+00:00
layout: post
slug: configuring-powerline-to-show-working-git-branch
title: Configuring powerline to show working Git branch
wordpress_id: 535
categories:
- Being Productive
- DevOps
- Programming
tags:
- bash
- fedora
- powerline
- shell
---

So the documentation for [Powerline](http://powerline.readthedocs.org/en/latest/index.html) kind of sucks. I followed [this](http://fedoramagazine.org/add-power-terminal-powerline) pretty good article on getting started with it. First thing I noticed however is that the `if` statement on the article doesn't work if you don't have powerline installed (which kind of defeats the purpose of having the `if` statement there at all).

```bash
# if powerline is installed, then use it
command -v powerline-daemon &>/dev/null
if [ $? -eq 0 ]; then
powerline-daemon -q
POWERLINE_BASH_CONTINUATION=1
POWERLINE_BASH_SELECT=1
. /usr/share/powerline/bash/powerline.sh
fi
```

Next up is the configuration. I primarily use my bash prompt as a way to indicate which branch I'm working in within a Git repository. You need to point at the `default_leftonly` theme which is pretty easy to find when you web search for it. The issue is everything seems to just point you at the powerline docs, which aren't the most clear.

First, start by creating a local configuration directory that will override the configuration for powerline for your user.

```bash
$ mkdir -p ~/.config/powerline
```

Then the next thing is to copy over the `config.json` from the main powerline configuration directory where you can find the available color schemes and other shell, i3, vim, etc themes.

(Again, the documentation kind of sucks on where the root of these configurations live...)

On my Fedora 22 system they live in `/etc/xdg/powerline/`. I then copy the `config.json` from that directory to `~/.config/powerline`

To get the Git branch stuff going, I modified the configuration file in the following way:

```javascript
--- /etc/xdg/powerline/config.json 2015-02-18 18:56:51.000000000 -0500
+++ /home/lmadsen/.config/powerline/config.json 2015-09-09 17:11:43.937522571 -0400
@@ -18,7 +18,7 @@
},
"shell": {
"colorscheme": "default",
- "theme": "default",
+ "theme": "default_leftonly",
"local_themes": {
"continuation": "continuation",
"select": "select"
```

To make it active you can run `powerline-config --reload`. If you have any errors in your configuration (I actually ran into this when playing with the colorscheme setting and used "solorized" instead of "solarized"), you can check it with `powerline-lint`.
