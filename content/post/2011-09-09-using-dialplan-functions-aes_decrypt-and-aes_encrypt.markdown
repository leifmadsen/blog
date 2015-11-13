---
author: leifmadsen
comments: true
date: 2011-09-09 13:28:47+00:00
layout: post
slug: using-dialplan-functions-aes_decrypt-and-aes_encrypt
title: 'Using Dialplan Functions: AES_DECRYPT() and AES_ENCRYPT()'
wordpress_id: 371
categories:
- Asterisk
tags:
- AES_DECRYPT
- AES_ENCRYPT
- Asterisk
- dialplan
- functions
- howto
- tutorial
- Using Dialplan Functions
---

I  recently asked on twitter how many people would be interested in a set of blog posts that focused on how to use the various dialplan functions in Asterisk, and I got quite a positive response. I posted that shortly before getting married, and now that I'm back into the groove of things, I'm going to take a shot at posting a bunch of content focused around Asterisk dialplan functions. If you don't know what Asterisk dialplan functions are, head on over to the online version of [Asterisk: The Definitive Guide (3rd edition)](http://ofps.oreilly.com/titles/9780596517342/index.html) (or [buy](http://www.amazon.com/Asterisk-Definitive-Guide-Guides/dp/0596517343/ref=sr_1_1?ie=UTF8&qid=1315572209&sr=8-1) it) and read the section on [dialplan functions](http://ofps.oreilly.com/titles/9780596517342/asterisk-DP-Deeper.html#asterisk-CHP-6-SECT-2). If you're still starting out with Asterisk, I highly suggest you start with the [dialplan basics](http://ofps.oreilly.com/titles/9780596517342/asterisk-DP-Basics.html) chapter.

Today we'll look at the first 2 dialplan functions in my list: `AES_DECRYPT()` and `AES_ENCRYPT()`

The AES_DECRYPT() and AES_ENCRYPT() functions work by passing strings to the functions, and they return a result. If you pass an unencrypted string to the AES_ENCRYPT() function it will return an encrypted string; vice-versa for the AES_DECRYPT() function. The two functions operate by passing a string and a key where the result is encoded  in base64.

Use case for these functions probably makes the most sense when you need to store data outside of the dialplan, perhaps passwords, pins, or other data passed in by the caller, but which you want to secure when you go to store it. Let's take an example where we create some dialplan that allows a caller to set their pin and store it in the database. For the sake of simplicity I'm not going to add any error checking (like to verify we really have data to work with, allow the caller to verify their extension, etc.):

```
exten => *88,1,NoOp()
 same => n,Playback(silence/1)
 same => n,Read(UserExtension,extension,3)                  ; read persons 3 digit extension unmber
 same => n,Verbose(2,Extension number: ${UserExtension})
 same => n,Read(PinEntry,agent-pass)                        ; ask for a pin number
 same => n,Verbose(2,Pin number: ${PinEntry})
 same => n,SayDigits(${PinEntry})                           ; say pin back to caller
 same => n,Set(DB(pin/${UserExtension})=${PinEntry})        ; store pin in the AstDB
 same => n,Playback(vm-goodbye)
 same => n,Hangup()
```

After the user enters their extension and pin, we store it in the AstDB. We can verify it was stored correctly by checking from the Asterisk CLI:

```
scrappy*CLI> database show pin
/pin/100 : 1234
1 results found.
```

Now let's modify our dialplan to store the pin in the database using a value returned from `AES_ENCRYPT()`.

```
exten => *88,1,NoOp()
 same => n,Playback(silence/1)
 same => n,Read(UserExtension,extension,3)
 same => n,Verbose(2,Extension number: ${UserExtension})
 same => n,Read(PinEntry,agent-pass)
 same => n,Verbose(2,Pin number: ${PinEntry})
 same => n,SayDigits(${PinEntry})
 same => n,Set(SpecialKey=1234qwerasdfzxcv)
 same => n,Set(EncryptedPin=${AES_ENCRYPT(${SpecialKey},${PinEntry})})
 same => n,Set(DB(pin/${UserExtension})=${EncryptedPin})
 same => n,Playback(vm-goodbye)
 same => n,Hangup()
```

And we can see the encoded string stored in the database:

```
scrappy*CLI> database show pin
/pin/100 : Je2G/qyHuGVKgvvXDwXjHA==
1 results found.
```

Of course anyone who has access to the AstDB from the Asterisk CLI is also going to have access to the Asterisk dialplan, so you'll have to do a better job than I have here of hiding the secret key being used for encrypting the data. Really all we're trying to do here is not make the list of pins and data in our AstDB quite so obvious. We could of course not use AstDB at all, and store the data remotely where we know people will have access to the data, but not access to the secret key on our Asterisk server.

Now lets look at the inverse by decoding the pin to authenticate someone.

```
exten => *77,1,NoOp()
 same => n,Playback(silence/1)
 same => n,Read(UserExtension,extension,3)                     ; get users extension
 same => n,Set(EncryptedPin=${DB(pin/${UserExtension})})       ; get encrypted pin from AstDB
 same => n,Read(PinEntry,agent-pass)                           ; get pin from user
 same => n,Set(SpecialKey=1234qwerasdfzxcv)
 same => n,Set(DecryptedPin=${AES_DECRYPT(${SpecialKey},${EncryptedPin})})                          ; decrypt the pin
 same => n,Playback(${IF($["${PinEntry}" = "${DecryptedPin}"]?pin-number-accepted:pin-invalid)})    ; if pin is correct, play number accepted, else, pin invalid
 same => n,Playback(vm-goodbye)
 same => n,Hangup()
```

That's it for now. Leave a comment if you like this format, and if you found this article useful. Thanks!
