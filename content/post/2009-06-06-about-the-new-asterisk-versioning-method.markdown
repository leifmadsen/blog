---
author: leifmadsen
comments: true
date: 2009-06-06 15:42:11+00:00
excerpt: Information about how the new 1.6.x series of Asterisk releases are published
  compared to the 1.2 and 1.4 series branches.
layout: post
slug: about-the-new-asterisk-versioning-method
title: About the new Asterisk versioning method
wordpress_id: 14
categories:
- Asterisk
tags:
- Asterisk
- pbx
- versioning
---

Recently I have been seeing more and more questions about how Asterisk is being released now, and what the 1.6.x versions really mean. I'll try and clear up some of your questions and make it more clear as to how Asterisk versions work. First, lets talk about the Asterisk 1.2 and 1.4 branches.


#### Previous release methodology


When we just had Asterisk 1.2 and 1.4, all new development was carried out in trunk (it still is) and only bug fixes went into the 1.2 and 1.4 branches. Currently, the 1.2 branch has been marked as EOL (End of Life), and is currently only receiving security updates. Bug fixes are reserved for the 1.4 branch. This means that until 1.6 came along, all new development was done in trunk, without the ability for people to get access to new features and functionality until the 1.6 branch was created. It's not to say the new functionality wasn't available, but with all the changes that can happen in trunk, running a production server based on it would require a very Asterisk savvy (and C code savvy) administrator.

Before we talk about 1.6, lets make sure we understand what trunk, branches, and tags mean.


#### Branches, and Tags, and Trunk; oh my!


Asterisk development is basically a linear process. All changes happen one after the other, and new features are always put on the end. This is referred to as _trunk_. All the latest changes to core Asterisk code, new features, and major changes take place here. This is why running trunk in production is not recommended, because the developers essentially have free reign as to what goes in here.

_Note: with the advent of [review board](http://www.review-board.org/), the larger commits that go into trunk are of much higher quality, as large changes are not put into trunk without any sort of peer review. The review board application allows these larger changes (such as new features, major core restructuring changes, etc.) to be reviewed by other developers to find common coding issues that would otherwise have had to be found in the wild._

Like a tree, the _branches_ grow from the trunk. These branches are referred to as 1.2, 1.4, etc. A branch is a snapshot of the trunk at the time of creation, and from there, has its own timeline. When a bug is found, fixed, and resolved, the resulting commit is then placed into trunk, and any branches that it effects. When a new feature is created, it is only put into trunk, thereby leaving the branches in a relatively known state that is safe for production use.

From a branch, we create snapshots in time called _tags_. These tags are the version numbers and tar ball files you can download from the [Asterisk.org](http://www.asterisk.org) website. These tags are numbered releases that never change, such as 1.4.18, 1.4.22, etc. In image 1.1, you can see a visual representation of the Asterisk branching and tagging process where the x-axis represents time.

[caption id="attachment_17" align="aligncenter" width="449" caption="Image 1.1 - Visual representation of Asterisk release branching and tagging."]![Image 1.1](http://leifmadsen.files.wordpress.com/2009/06/asterisk_release_tree.jpg)[/caption]


#### Understanding the Asterisk 1.6 release process


With the advent of Asterisk 1.6, the release process has differed slightly, in that there are multiple 1.6 branches supported at any given time. The reason for this is because the time frame between the creation of the 1.0 & 1.2 branches, and the 1.2 & 1.4 branches was so great (approximately 1 year in the former, and 2 years in the latter!) that new features would sit in trunk, and many changes would take place over that period of time. Due to the rapid development of Asterisk, these changes were grandiose and thus the user experience between these releases were such that major changes had taken place. Backwards compatibility was difficult to maintain, and simply, who wants to wait 3 years to get the next great feature?

So with Asterisk 1.6, a new release process that allows branches to be created in a more regular fashion (approximately 6-8 months) was developed. Whenever a branch is created, we now update the 3rd most significant digit, which represents a new branch with new features, and the 4th most significant digit is now the tag number in that release. So for example, we have the branch Asterisk 1.6.0, which is a branch created from trunk at a period in time, and within that branch, bug fixes are performed, but no new features are added. The tags from this branch will be version numbers such as 1.6.0.0, 1.6.0.1, 1.6.0.2, etc. Then some period in time, a new branch will be created from trunk such as 1.6.1 (note that the 3rd significant number has increased by one). Within this branch will be new features and changes — that different of the 1.6.0 branch. Within the 1.6.1 branch, we'll have tags just like all our other branches, such as: 1.6.1.0, 1.6.1.1, 1.6.1.2, etc.

This process continues throughout the lifetime of the 1.6 series of Asterisk. The trunk continues to have development, new features merged and potential core changes to make Asterisk more efficient (which would otherwise be deemed too invasive for a release branch) are committed. The regular release nature of this process allows less drastic changes between major versions (and note that the difference between a 1.6.0 and a 1.6.1 *is* considered a major version upgrade, similar in nature to an upgrade between 1.2 and 1.4, but not quite so drastic), and access to new features on a more regular basis. Because these are considered a major change between versions, it is in your interest to read the UPGRADE-1.6.txt files in your Asterisk source, and to test thoroughly before deploying in a production environment.

It should be noted that at any given time, there will be at least 3 branches of the 1.6 nature maintained. That means bug fixes and maintenance will be performed on your preferred branch for an extended period of time. For example, because there can be code refactoring, and core changes between 1.6.x versions (where x is the major version number), you may wish to maintain your production system on the 1.6.0 branch while your development system is running the 1.6.1 series. This way you don't have to worry about moving your 1.6.0 system immediately to a 1.6.1 based branch as soon as it is created. Image 1.2 shows a visual representation of the 1.6 release process, which should look similar to the release process between 1.2 and 1.4. The x-axis still represents time, but in this case, time is not over quite so long a period.





[caption id="attachment_18" align="aligncenter" width="449" caption="Image 1.2 - Visual representation of the Asterisk 1.6 release process"]![Image 1.1 - Visual representation of the Asterisk 1.6 release process](http://leifmadsen.files.wordpress.com/2009/06/asterisk_1-6_release_tree.jpg)[/caption]


#### So which version do I use?


It always comes down to the question of, "so which version do I use?" and this can be a tricky one to answer. It probably boils down to what features you need to utilize. By checking the CHANGES file in your Asterisk source tree, you can see what changes have happened between each of the various branches (i.e. the differences between 1.6.0 and 1.6.1). While writing this article, I was asked by someone on IRC the question, "What version do you recommend?", and the answer I gave was, "I recommend the version that has the features you require, and that passes the testing you have done prior to rolling it out". He followed up with, "But they all have the feature I require!", to which I responded, "Do some forward planning, and try to determine that the version you pick has the features you may possibly require in the future so that you don't have to re-architect your system sooner than you want". This can save you a lot of time and effort. Do some testing, and play with all the various branches on a development server. See what dialplan applications and functions exist, and how they work. Try to determine what kinds of things you need your phone system to do, and make sure the version you pick can do it. You can also make use of the various mailing lists and IRC chat rooms (asterisk-users mailing list, and #asterisk IRC channel) to ask specific questions if you're not able to find an answer.

Hopefully this has made the release process a bit more clear. If you have any questions or comments, please feel free to leave a comment, and I'll try to address all your issues as best I can.
