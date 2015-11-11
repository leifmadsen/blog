---
author: leifmadsen
comments: true
date: 2012-08-22 18:49:43+00:00
layout: post
slug: selecting-chef-servers-with-environment-variables
title: Selecting Chef Servers With Environment Variables
wordpress_id: 473
categories:
- DevOps
tags:
- bash
- chef
- devops
- environment variables
- knife
- ps1
- ruby
---

Today I got playing around with dynamically selecting different chef servers in preparation for migrating some of [our](http://coredial.com) nodes away from our chef-dev server to our chef-live server (which I'm currently in the process of building and populating with data). I had been talking in the #chef IRC channel a few weeks back about making things dynamic, or at least easily switchable, when using multiple chef servers for different groups of servers in an environment.

What I want to do, is be able to set an environment variable at my console in order to switch between chef servers. Previously I had been doing this with different files in my ~/.chef/ directory and changing symlinks between the files. This method works, but is kind of annoying. So with the help of some of the folks in #chef, and with [this gist](https://gist.github.com/3176332) of a sample file that someone is using for their hosted chef environment, I was able to build my own knife.rb and commit it to our chef.git repository.

In our **chef.git** repository, I created a directory **.chef** and placed a **knife.rb** file in it:

```bash
$ cd ~/src/chef-repo
$ mkdir .chef
$ touch .chef/knife.rb
```

I then filled **knife.rb** with the following contents:

```ruby
current_dir = File.dirname(__FILE__)

sys_user = ENV["USER"]

log_level                :info
log_location             STDOUT
node_name                sys_user
client_key               "#{ENV["HOME"]}/.chef/#{ENV["KNIFE_ENV"]}/#{ENV["USER"]}.pem"
validation_client_name   "chef-validator"
validation_key           "#{ENV["HOME"]}/.chef/#{ENV["KNIFE_ENV"]}/validator.pem"
chef_server_url          "http://chef-#{ENV["KNIFE_ENV"]}.shifteight.org:4000"
cache_type               'BasicFile'
cache_options( :path => "#{ENV['HOME']}/.chef/checksums" )
cookbook_path            [ "#{current_dir}/../cookbooks", "#{current_dir}/../site-cookbooks" ]
```

The main key is the KNIFE_ENV environment variable which I set using: `export KNIFE_ENV=dev` or `export KNIFE_ENV=live`

After setting the environment variable, which server I'm using is selected for me. Additionally, I copied my validation.pem and client.pem files into corresponding directories in my ~/.chef/ directory: `$ mkdir ~/.chef/{live,dev}`

With all that done, I can now easily switch between our different servers in order to start the migration of our nodes. (I might create another blog post about that in the future if I get a chance.)

"BUT HOW DO I KNOW WHICH ENVIRONMENT I'M WORKING WITH?!?!?!", you say? Oh fancy this little PS1 and function I added to my ~/.bashrc file:

```bash
if [ "$KNIFE_ENV" == "" ]; then
 export KNIFE_ENV="dev"
fi

function which_env {
  if [ "$KNIFE_ENV" == "live" ]; then
    echo "31"
  else
    echo "32"
  fi
}

export PS1='[\u@\h \[\033[0;36m\]\W$(__git_ps1 "\[\033[0m\]\[\033[0;33m\](%s) \[\033[0;`which_env`m\]~$KNIFE_ENV~")\[\033[0m\]]\$ '
```
Is nice :)
