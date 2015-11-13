---
author: leifmadsen
comments: true
date: 2009-07-17 17:21:15+00:00
layout: post
slug: howto-read-a-value-from-a-file-and-say-it-back
title: 'HowTo: Read a value from a file, and say it back'
wordpress_id: 73
tags:
- Asterisk
- curl
- func_odbc
- howto
- shell
---

### Preamble



Today on the [VoIP Users Conference](http://www.voipusersconference.org/) we discussed my request for recipe ideas in order to start developing some additional documentation. Specifically, I'm looking for problems that are simple, common problems that can be solved in the dialplan, and which are good examples of the dialplan language (markup, script, yadda yadda).

One of the suggestions was something posted to the Asterisk mailing list which was pretty straight forward: to read in the contents of a file, where the file contained a number which was the current temperature. This file was created by an external script, and the poster was looking for how to read in the contents of that file, and play back something that would say the number, followed by "degrees".

The discussion delved into some possible solutions, and delved into the problem with writing Asterisk recipes in general; that there are always several ways to skin the same cat. Below I will mention some of the examples that had come up on the conference call in the Discussion section, and will then show a dialplan (that works on Asterisk 1.4) that will solve the problem proposed in the Solution section.



### Problem


To read the contents of a file, where the contents will contain a number, that needs to be read back to the caller, followed by the word "degrees".



### Solution


```
[subSayCurrentTemperature]
exten => start,1,Verbose(2,Saying the current temperature back to channel ${CHANNEL})

; first, lets verify the the file exists for reading in data
exten => start,n,Set(PATH_TO_FILE=/tmp/current_temp.txt)
exten => start,n,Set(FILE_STATUS=${STAT(e,${PATH_TO_FILE})})
exten => start,n,GotoIf($["${FILE_STATUS}" = "" | "${FILE_STATUS}" = "0"]?no_file,1)

; next lets read in the value from the file since it exists
exten => start,n,Set(MAX_FILE_CHARACTERS=256)
exten => start,n,ReadFile(TEMPERATURE=${PATH_TO_FILE},${MAX_FILE_CHARACTERS})
exten => start,n,GotoIf($[${ISNULL(${TEMPERATURE})}]?no_file,1)                               ; verify we got a value

; say the temperature
exten => start,n,Playback(silence/1)
exten => start,n,SayNumber(${TEMPERATURE})
exten => start,n,Playback(en/degrees&en;/fahrenheit)
exten => start,n,Return()

exten => no_file,1,Verbose(2,File does not exist)
exten => no_file,n,Playback(silence/1)
exten => no_file,n,Playback(en/feature-not-avail-line)
exten => no_file,n,Return()
```

And then you can setup some sort of test number that will call the subroutine (I'm using `GoSub()`).

```
[incoming]
exten => 555,1,Verbose(2,Checking temperature)
exten => 555,n,GoSub(subSayCurrentTemperature,start,1)
exten => 555,n,Hangup()
```



### Discussion
The solution above is really the "right" way to do it in Asterisk. But with Asterisk, there always seems to be many "right" ways to solve the same solution. Because the problem was to read in the contents of a file and to say the contents back, then the solution I provided certainly solves that problem directly in dialplan without any external scripts, or dropping to the console.

There were several other solutions that could have been provided for this solution since there was an external PHP script that was generating the file and its contents. That script could have done any of the following:

* Execute a shell command, and write the contents to the Asterisk database: `asterisk -rx "database put temperature current 60"`
* Write the contents to a relational database such as MySQL and use func_odbc:  `Set(TEMPERATURE=${ODBC_TEMP()})`
* Setup a webpage and parse it with curl: `Set(TEMPERATURE=${CURL(http://website.tld/temperature.php)})`
* On Asterisk 1.6, there is the SHELL() function: `Set(TEMPERATURE=${SHELL(cat /tmp/current_temperature.txt)})`


I particularly like the curl solution since it allows the script to lookup the temperature when the CURL() function calls it, which means it can be real time and not delayed like writing to a text file can be.

So like with all things Asterisk, there are always many inventive ways to solve the same solution.
