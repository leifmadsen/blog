+++
date = "2017-01-04T15:42:23-05:00"
categories = ["tripleo", "linux", "bash", "ansible"]
keywords = ["ansible", "bash", "console", "linux"]
description = ""
title = "Finding available Ansible tags in playbooks and roles"

+++

Today I went down a yak shaving path trying to figure out how to get all the
available tags in a fairly complicated plethora of Ansible playbooks and roles.
One of these such situations involves TripleO Quickstart, which is made up of
several different playbooks and repositories of different roles.
<!--more-->

Of course there is the nice feature of `ansible-playbook` that you could run
`ansible-playbook --list-tags` which outputs something like the following:

```
playbook: playbooks/quickstart.yml

  play #1 (localhost): Add the virthost to the inventory	TAGS: [provision]
      TASK TAGS: [provision]

  play #2 (virthost): Tear down non-root user on virt host	TAGS: [teardown-provision,teardown-all]
      TASK TAGS: [teardown-all, teardown-provision]

  play #3 (localhost): Add virthost to inventory	TAGS: [provision]
      TASK TAGS: [provision]

  play #4 (virthost): Create non root user on the virthost	TAGS: [provision]
      TASK TAGS: [provision]

  play #5 (virthost): Create target user on virt host	TAGS: [provision]
      TASK TAGS: [provision]
```

The problem I've found is that running from the top level playbook (if there is
even one) requires that all the other playbooks and roles are included in it to
know for certain that you've gotten all the available tags.

So instead of relying on that, I built out a bash script that goes through the
playbooks in a loop, teasing out all the available tags, creating a list of
them, then sorting them and spitting out the unique values.

In all its infamous glory...

```
for i in $(ls playbooks/*.yml)
do
    ansible-playbook --list-tags $i 2>&1
done |
grep "TASK TAGS" |
cut -d":" -f2 |
awk '{sub(/\[/, "")sub(/\]/, "")}1' |
sed -e 's/,//g' |
xargs -n 1 |
sort -u
```

I told you it was a yak shaving exercise. And now that our yak sits in its
birthday suit, we can analyze all the bits of what made this monstrosity a
reality.

First, we setup a `for` loop that runs through all our playbooks (it is assumed
that any roles you care about are called at least once from any of the
playbooks in your repository). We then request Ansible to return us the
available tags that is called from the playbook.

```
for i in $(ls playbooks/*.yml)
do
    ansible-playbook --list-tags $i 2>&1
done |
```

Then we `grep` out the list of tags.

```
grep "TASK TAGS" |
```
```

Grab just the tags themselves.

```
cut -d":" -f2 |
```

Strip off the opening and closing braces.

```
awk '{sub(/\[/, "")sub(/\]/, "")}1' |
```

Remove the comma separating lists of tags.

```
sed -e 's/,//g' |
```

Place each of the various tags on their own line.

```
xargs -n 1 |
```

And sort the tags, returning only the unique values.

```
sort -u
```

# Conclusion

The funny thing, is I had an even more complicated solution as I found
`shyaml`[1][1] which is pretty damn cool, but really is kind of a pain to work
with if you're trying to filter on sequences (which is pretty much all my
Ansible playbooks consist of).

Additionally, it hates the `block` statement, and `shyaml` basically bails at
that point. The script I had before also only found a subset of the tags.

I may still be missing some things as even Ansible was bombing on some
particular syntax in the playbooks, although I'm relatively assured that I've
gotten all the tags.

[1] https://github.com/0k/shyaml
