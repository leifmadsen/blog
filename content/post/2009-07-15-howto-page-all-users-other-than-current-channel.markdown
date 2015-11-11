---
author: leifmadsen
comments: true
date: 2009-07-15 18:29:02+00:00
layout: post
slug: howto-page-all-users-other-than-current-channel
title: 'HowTo: Page() all users, other than current channel'
wordpress_id: 47
categories:
- Asterisk
tags:
- Asterisk
- howto
- Page()
---

I was asked on IRC by bhodder how to Page() all users, other than the current channel (i.e. he had a list of people to call, but one of the channels listed could be the person paging, and he didn't want them paged).

So I wrote up the following little dialplan script which takes the list of users, and compares it against the current channel, and simply rebuilds the list without the current channel in it prior to calling the Page() application.

```ruby
exten => start,1,NoOp()

; all users we want to page (potentially)
exten => start,n,Set(ALL_USERS_TO_PAGE=SIP/100&SIP;/101&SIP;/102)

; what is our channel name? (without the unique bit)
exten => start,n,Set(CURRENT_CHANNEL=${CUT(CHANNEL,-,1)})

; initialize loop counter
exten => start,n,Set(LOOP_COUNT=1)
exten => start,n,Set(WORKING_USER=${CUT(ALL_USERS_TO_PAGE,&,${LOOP_COUNT})})

; while we still have values, loop
exten => start,n,While($["${WORKING_USER}" != ""])

; if the working user is the current user, do not add them
exten => start,n,GotoIf($["${WORKING_USER}" = "${CURRENT_CHANNEL}"]?skip_add_user)

; if users to page is not null, then prefix with ampersand
exten => start,n,Set(USERS_TO_PAGE=${IF($["${USERS_TO_PAGE}" = ""]?${WORKING_USER}:${USERS_TO_PAGE}&${WORKING_USER})})
exten => start,n(skip_add_user),NoOp()

; increment loop
exten => start,n,Set(LOOP_COUNT=$[${LOOP_COUNT} + 1])

; get new working user
exten => start,n,Set(WORKING_USER=${CUT(ALL_USERS_TO_PAGE,&,${LOOP_COUNT})})
exten => start,n,EndWhile()

; page users
exten => start,n,Page(${USERS_TO_PAGE})
exten => start,n,Hangup()
```

Essentially how it works is to take the ${ALL_USERS_TO_PAGE} variable and use the CUT() function to check each of the fields (which are separated by an ampersand (&)), and to compared that to the ${CURRENT_CHANNEL} variable, which is taking the ${CHANNEL} variable, and stripping off the unique bit of the string (i.e. SIP/100-44adf43p) to compare that with the ${WORKING_CHANNEL} variable (which contains the value of field ${LOOP_COUNTER}, where ${LOOP_COUNTER} is field number 1 through 3).

The While() checks to make sure we still have a value, and when we don't, we exit (i.e. ${LOOP_COUNTER} will contain 4, and field 4 will be blank).

Once we've rebuilt our string ${USERS_TO_PAGE}, we exit the loop, and use that in the Page() application. If all goes well, we should only page the users who are not us :)

This was created for a user and not tested by me. If you have any issues, leave a comment, and I'll update the code with anything that doesn't work. If this works first try, I'll be shocked and very happy!
