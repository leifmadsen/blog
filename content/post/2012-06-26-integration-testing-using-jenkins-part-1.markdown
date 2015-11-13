---
author: leifmadsen
comments: true
date: 2012-06-26 12:51:30+00:00
layout: post
slug: integration-testing-using-jenkins-part-1
title: Integration Testing Using Jenkins (Part 1)
wordpress_id: 447
categories:
- DevOps
tags:
- chef
- devops
- foodcritic
- git
- jenkins
- minitest
- ruby
- rvm
---

So for the last week or so, I've been tasked at [CoreDial](http://www.coredial.com) with adding our own set of integration testing now that we're moving to a more formal deployment method using [chef](http://wiki.opscode.com/display/chef/Home). After much pestering of questions to [thehar](https://github.com/thehar) of [Lookout Mobile Security](https://www.mylookout.com/) and with help of Google, #chef and jhansche in #jenkins I've finally got a nice clean proof of concept that we can evaluate and likely deploy.

I'll come back later with another article on my installation issues with jenkins and the solutions that I solved (nothing too terribly complicated), but what I wanted to blog about was the two types of tests that I've been focusing on and was able to finally solve.

First, I wanted to simply get a working test going in [jenkins](http://jenkins-ci.org/) since I'd never used it before and needed a minimum viable product to look at. Based on a recommendation from thehar a couple weeks ago, I looked at [foodcritic](http://acrmp.github.com/foodcritic/), got that working, and with their instructions, was able to get that integrated for my first automated test in jenkins.

The main problem I had was really getting an environment path variable set so that I could execute a ruby shell (`#!/usr/bin/env rvm-shell 1.9.3`, in the foodcritic instructions). After some searching, I came across a hint (sorry, I've misplaced the link) that stated I needed to add `source /etc/profile` to the bottom of my /etc/default/jenkins file, which worked marvellously to get the command I was trying to run to go. (Note that I installed on Ubuntu 12.04 for this test.)

(Prior to that, I installed [rvm](https://rvm.io/rvm/install/) and then ran the multi-user instructions to get ruby 1.9.3 installed. I also installed foodcritic via `gem install foodcritic` which depends on ruby 1.9.2+.)

Having created my first job, I filled in the Git information to connect to my git server. I ran into a few issues there, and needed to create a new .ssh directory in /var/lib/jenkins/.ssh/ (/var/lib/jenkins is the $HOME directory of jenkins). I then placed the appropriate authentication keys in the directory, but was still having issues with connecting to the server. It ended up being that I needed to add a `config` file to the .ssh directory with the following contents:

```bash
Host coredial-git
  HostName gitserver.hostname.com
  User git
  IdentityFile /var/lib/jenkins/.ssh/id_rsa.key
  StrictHostKeyChecking no
```

After adding this, then I could set the repository URL to `git@coredial-git:chef-repo.git` and the branch specifier to something like `*/feature/ENG-*` in order to test all our engineering testing branches. I then setup **Poll SCM** with polling schedule `*/5 * * * *` (I set to */1 at first for testing, and will likely increase this further, or add a post-commit hook to git.)

The actual command I'm running in the Execute Shell section looks like this:

```ruby
#!/usr/bin/env rvm-shell 1.9.3
foodcritic -f any site-cookbooks/my_awesome_cookbook
```

Then I saved the test, made some changes, and during the poll was able to trigger off both expected failed and expected passing tests. Very cool indeed!
