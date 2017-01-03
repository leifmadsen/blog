+++
date = "2017-01-03T14:34:38-05:00"
categories = ["centos", "linux", "python"]
keywords = ["ssl", "letsencrypt", "security", "linux", "centos6", "python"]
description = ""
title = "Installing Python 2.7 on CentOS 6.x"

+++

I recently had a need to install Python 2.7 on an older CentOS 6 machine since
I wanted to generate some SSL certificates for my web server. On CentOS 6, then
default Python installation is 2.6, which doesn't seem to work for Let's
Encrypt.
<!--more-->

I did a bunch of searching which basically led me to the conclusion that 1) you
can't (easily) upgrade a CentOS 6 based system to CentOS 7 (which would provide
a path to Python 2.7), and 2) that installing Python 2.7 also isn't all that
trivial.

After some more searching, I found the following gist post which works
perfectly for me to get the SSL certificates created from Let's Encrypt.
Unfortunately I haven't yet figured out how to properly run this from a cronjob
so that the certificates are updated, but I have an idea. I'll update this blog
if I get around to figuring it out :)

https://gist.github.com/dalegaspi/dec44117fa5e7597a559

Below is the entire contents of the previously posted link, in case the gist
contents goes away.

> Installing Python 2.7 on Centos 6.5 =============================
> 
> Centos 6.* comes with Python 2.6, but we can't just replace it with v2.7
> because it's used by the OS internally (apparently) so you will need to
> install v2.7 (or 3.x, for that matter) along with it.  Fortunately, CentOS
> made this quite painless with their [Software Collections
> Repository](http://wiki.centos.org/AdditionalResources/Repositories/SCL)
> 
>     sudo yum update # update yum 
>     sudo yum install centos-release-scl # install SCL
>     sudo yum install python27 # install Python 2.7
> 
> To use it, you essentially spawn another shell (or script) while enabling the
> newer version of Python:
> 
>     scl enable python27 bash
> 
> To install additional libraries, you will need to install PIP:
> 
>     cd /opt/rh/python27/root/usr/bin/ # cd to the directory where SCL installs python 
>     sudo LD_LIBRARY_PATH=$LD_LIBRARY_PATH ./easy_install-2.7
>     pip
> 
> once installed, you can install PIP using `pip2.7`, e.g.:
> 
>     sudo LD_LIBRARY_PATH=$LD_LIBRARY_PATH ./pip2.7 install requests
> 
> *NOTE*: if your username doesn't require root to install software, then
> `LD_LIBRARY_PATH` and `PATH` is set up for you automatically by `scl`.  Also
> keep in mind that using SCL outside a shell (e.g., cronjobs) [isn't quite
> straightforward](http://stackoverflow.com/questions/16631461/scl-enable-python27-bash).
> Also, using `virtualenv` [poses a challenge as
> well](http://digiactive.com.au/blog/2013/12/28/setting-up-python-2-dot-7-on-centos-6-dot-4-the-really-easy-way/).
