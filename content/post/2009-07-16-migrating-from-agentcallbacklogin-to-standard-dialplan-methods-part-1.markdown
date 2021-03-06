---
author: leifmadsen
comments: true
date: 2009-07-16 02:59:34+00:00
layout: post
slug: migrating-from-agentcallbacklogin-to-standard-dialplan-methods-part-1
title: Migrating from AgentCallbackLogin() to Standard Dialplan Methods (part 1)
wordpress_id: 59
categories:
- Asterisk
tags:
- AddQueueMember()
- AgentCallbackLogin()
- Asterisk
- migration
- pbx
---

The purpose of this article is to ease the migration from AgentCallbackLogin() to using standard dialplan applications to solve the problem of calling back queue members (agents) who are logged into a queue.

We will look at some of the common uses of AgentCallbackLogin(), and explore how to perform the same functionality using the commonly available dialplan applications in Asterisk.

The version of Asterisk used in the following examples is based on a recent version of Asterisk 1.4, namely any version from 1.4.25 and beyond. This is because in 1.4.25, a backport of the state interface features in 1.6.x were put into Asterisk 1.4 in order to solve some issues with incorrect device state on Local channels. We'll be using these state interface features in the examples that follow.

All agents (queue members) will be utilizing the SIP channel driver as it is the only channel driver that contains code for true device state monitoring.



## Starting Simple


Lets start with a simple example of how to use AgentCallbackLogin(), and then look at how we can accomplish the same thing with some dialplan logic. First, we need to setup a queue and add some agents to the system. We'll also setup the SIP devices, and configure the dialplan.

While it may seem excessive in the next few sections to setup something that we're going to replace anyways, the majority of the configuration is going to be reused in the sections that follow.



### Setting up the SIP devices


First we need to configure sip.conf for a couple of devices. One of these will be used for calling the Queue(), while the other will be the agent that will be logged into the queue.

Under the [authentication] header, we will create a template called [phones] that will be used for all the phones. We're going to use some MAC addresses for the device names, which is how they will authenticate. This is a best practice in general, as we typically want to abstract the device name away from any sort of identifier, such as extension numbers and agent names.

```php
; Create a template we'll use for our phones
[phones](!)
type=friend
host=dynamic
context=from-devices
canreinvite=no
dtmfmode=rfc2833
disallow=all
allow=ulaw
call-limit=5
```

Note that we have the 'call-limit' option enabled. This is necessary for Asterisk to determine whether the device is in use or not. You can set this number to anything you want, as long as it is set.

```php
; Define local devices here
[000A8A2150CB](phones)
username=000A8A2150CB
secret=welcome

[00085D193AB5](phones)
username=00085D193AB5
secret=welcome

[00085D182ACF](phones)
username=00085D182ACF
secret=welcome
```

The [general] section was left pretty much default, with only a couple of minor tweaks related to the local system configuration. One of the tweaks that should be mentioned however is the 'limitonpeers' option. By enabling this, you will get better (correct) InUse status on devices, as outgoing calls will have the call limits applied to the peer structure, thereby giving you the correct device status.

From the sip.conf configuration file:

```php
limitonpeers = yes             ; Apply call limits on peers only. This will improve
                                ; status notification when you are using type=friend
                                ; Inbound calls, that really apply to the user part
                                ; of a friend will now be added to and compared with
                                ; the peer limit instead of applying two call limits,
                                ; one for the peer and one for the user.
                                ; "sip show inuse" will only show active calls on
                                ; the peer side of a "type=friend" object if this
                                ; setting is turned on.
```

From the Asterisk CLI, we need to reload chan_sip, and get our phones registered.

```bash
*CLI> module reload chan_sip.so
Reloading SIP
```

```bash
*CLI> sip show peers
Name/username              Host            Dyn Nat ACL Port     Status
00085D182ACF/00085D182ACF  192.168.128.138  D          5501     Unmonitored
00085D193AB5/00085D193AB5  192.168.128.145  D          5430     Unmonitored
000A8A2150CB/000A8A2150CB  (Unspecified)    D          0        Unmonitored
3 sip peers [Monitored: 0 online, 0 offline Unmonitored: 2 online, 1 offline]
```



### Configuring Agents


Next we want to configure a couple of agents which we'll use from the AgentCallbackLogin() test we'll develop shortly.

In agents.conf, configure the following at the bottom of the sample configuration file. Be sure to comment out any sample agents that may not be commented in the sample configuration.

```bash
agent => 100,1234,Leif Madsen
agent => 101,1234,Russell Bryant
agent => 102,1234,Mark Michelson
```

Save the file, and reload the chan_agent module.

```bash
*CLI> module reload chan_agent.so
-- Reloading module 'chan_agent.so' (Agent Proxy Channel)
```

Then verify the agents have been loaded into memory.

```bash
*CLI> agent show
100          (Leif Madsen) not logged in (musiconhold is 'default')
101          (Russell Bryant) not logged in (musiconhold is 'default')
102          (Mark Michelson) not logged in (musiconhold is 'default')
3 agents configured [0 online , 3 offline]
```



### Configuring Queues


We now want to configure a queue, and add the agents to that queue. We'll use the previously added agents from the agents.conf file in queues.conf. We're going to add a new queue called 'primary' with just the bare minimum configuration settings to get the queue working. Asterisk will then use default values for anything else we haven't specifically configured.

In queues.conf, we can add the primary queue like so.

```php
[primary]
strategy=ringall
timeout=15
ringinuse=no
autopause=yes

member => Agent/100
member => Agent/101
member => Agent/102
```

We're using the ring all strategy which will ring all available queue agents. Additionally, we've setup the timeout (number of seconds to ring the agents) to 15 seconds, configured Asterisk to mark the agent as in use when ringing the agent (so they don't get multiple calls), and automatically pause any agents who do not answer within the allotted time out period.

We've added our three agents, 100, 101, and 102 with the member lines.

Next we need to reload the app_queue module to load the queue configuration into memory.

```
*CLI> module reload app_queue.so
-- Reloading module 'app_queue.so' (True Call Queueing)`
```

```
*CLI> queue show
primary      has 0 calls (max unlimited) in 'ringall' strategy (0s holdtime)
Members:
Agent/102 (Unavailable) has taken no calls yet
Agent/101 (Unavailable) has taken no calls yet
Agent/100 (Unavailable) has taken no calls yet
No Callers
```



### Configuring the Dialplan


Next, we need to add some dialplan logic which allows use to login the agents to the queue, and then to test that we can get calls to the agents by calling into the queue.

The following dialplan will accomplish what we want.

```
[general]
static=yes
writeprotect=no
clearglobalvars=no

[globals]

[default]

[from-devices]
; simple usage of AgentCallbackLogin()
;
exten => 999,1,Verbose(2,Logging in agent)
exten => 999,n,Playback(silence/1)
exten => 999,n,AgentCallbackLogin(,,${CUT(CUT(CHANNEL,/,2),-,1)}@agent_callback)
exten => 999,n,Hangup()

; calling 'primary' queue
;
exten => 555,1,Verbose(2,Calling into the primary queue)
exten => 555,n,Playback(silence/1)
exten => 555,n,Queue(primary)
exten => 555,n,Hangup()

[agent_callback]
exten => _[A-Za-z0-9].,1,Set(EXTENSION=${EXTEN})
exten => _[A-Za-z0-9].,n,Goto(start,1)

exten => start,1,Dial(SIP/${EXTENSION})
```

What we're doing in the [from-devices] context at extension 999 is allow the agent to login by dialing 999, which will then prompt for their agent ID and password. These are the extensions and passwords we configured in agents.conf.

The format of the AgentCallbackLogin() application is as follows:

```
AgentCallbackLogin([AgentNo][,[options][,[exten]@context]])
```

We are only passing the third option, which is exten@context, where exten is the extension we will call, and the context is where the extension will be called.

The part of the AgentCallbackLogin() application which may be slightly confusing is this:

```
${CUT(CUT(CHANNEL,/,2),-,1)}@agent_callback
```

What we're doing is using the CHANNEL variable, which is automatically populated by Asterisk when a channel is created. It will look something like:

```
SIP/00085D182ACF-017b24f0
```


> **Note**:
>
> The `CUT()`` function works by providing the field separator, and then the field we want. We are nesting two `CUT()` functions together to first look for the front slash (/) separator, and return the 2nd field (00085D182ACF-017b24f0) and that is then given to the outside `CUT()` function, which looks for the hyphen (-) separator, and returns the first field (00085D182ACF).
>
> The part on the left side of the front slash is the technology (SIP), and to the right is the device identifier we've configured in sip.conf, but with a hyphen and unique identifier tacked onto the end. What we're doing with the CUT() function, is to strip off the SIP/ part of the CHANNEL application, along with the unique identifier, including the hyphen. This will then leave the following:
>
> `00085D182ACF`

When we login, we then are telling the `Queue()` application to call Agent/100 by dialing 00085D182ACF in the `[agent_callback]` context. This context then will dial `SIP/00085D182ACF`, which rings the device.

The reason we do it this way is because we then create what is effectively a hot-desking application, where an agent can login from any device using their agent ID.

Lets reload the dialplan and then we can test our application.
```
*CLI> dialplan reload
```



### Logging in the Agent


Now that we've configured our devices, agents, queues, and dialplan, we can now go about testing it. We'll start by logging in an agent to the 'primary' queue, and call it from another device in order to show how the AgentCallbackLogin() application works now.

First, start by dialing extension 999 which will then prompt you for your Agent ID (100) followed by the password (1234). After each prompt be sure to press the # key. After you've logged in you can verify your status from the Asterisk CLI.

```
*CLI> agent show
100          (Leif Madsen) available at '00085D182ACF@agent_callback'
101          (Russell Bryant) not logged in (musiconhold is 'default')
102          (Mark Michelson) not logged in (musiconhold is 'default')
3 agents configured [1 online , 2 offline]
```

And then verify that our agent is available in the queue.

```
*CLI> show queues
primary      has 0 calls (max unlimited) in 'ringall' strategy (0s holdtime)
Members:
Agent/102 (Unavailable) has taken no calls yet
Agent/101 (Unavailable) has taken no calls yet
Agent/100 (Not in use) has taken no calls yet
No Callers
```



### Testing the Queue


We can now test our queue by dialing extension 555 from our second phone, which will then cause the queue to dial our agent.

Lets step through the following console output to determine what happened when we dialed 555.

```
*CLI>
-- Executing [555@from-devices:1] Verbose("SIP/00085D193AB5-017b24f0", "2|Calling into the primary queue") in new stack
== Calling into the primary queue
-- Executing [555@from-devices:2] Playback("SIP/00085D193AB5-017b24f0", "silence/1") in new stack
--  Playing 'silence/1' (language 'en')
```

Here we enter the Queue() application.

```
-- Executing [555@from-devices:3] Queue("SIP/00085D193AB5-017b24f0", "primary") in new stack
```

And now the music on hold starts for the incoming caller while we attempt to dial an agent.

```
-- Started music on hold, class 'default', on SIP/00085D193AB5-017b24f0
```

Then the Queue() application attempts to call agent 100, which is called via the Local channel.

> **Note**:
>
> The Local channel in Asterisk is a pseudo channel that permits applications to execute dialplan logic in place of calling a standard channel, like a SIP channel.
> 

The Local channel is dialing extension 00085D182ACF within the [agent_callback] context. When we logged in agent 100, we told the AgentCallbackLogin() application that agent 100 can be reached by executing extension 00085D182ACF inside the [agent_callback] context.

```
-- outgoing agentcall, to agent '100', on 'Local/00085D182ACF@agent_callback-dabf,1'
```

The first priority of the [agent_callback] context saves the dialed extension to a channel variable. The reason we do this is because we're using a complex pattern match in the dialplan (see Configuring the Dialplan earlier) which could be error prone to type several times. So we save the value of ${EXTEN} to the EXTENSION channel variable, and use that in an easier to type extension name (i.e. start)

```
-- Executing [00085D182ACF@agent_callback:1] Set("Local/00085D182ACF@agent_callback-dabf,2", "EXTENSION=00085D182ACF") in new stack
```

Now that we've saved the extension matched by our pattern, we can Goto() the 'start' extension.

```
-- Executing [00085D182ACF@agent_callback:2] Goto("Local/00085D182ACF@agent_callback-dabf,2", "start|1") in new stack
-- Goto (agent_callback,start,1)
```

The 'start' extension simply performs the Dial() over a SIP channel to the device we want to call, which is device 00085D182ACF (as configured in sip.conf).

```
-- Executing [start@agent_callback:1] Dial("Local/00085D182ACF@agent_callback-dabf,2", "SIP/00085D182ACF") in new stack
-- Called 00085D182ACF
```

The agent then hears ringing at their device.

```
-- SIP/00085D182ACF-017b9510 is ringing
-- Agent/100 is ringing
```

After the agents phone rings, they answer it, and music on hold is stopped.

```
-- SIP/00085D182ACF-017b9510 answered Local/00085D182ACF@agent_callback-dabf,2
-- Agent/100 answered SIP/00085D193AB5-017b24f0
-- Stopped music on hold on SIP/00085D193AB5-017b24f0
```



### Logging Out the Agent


Prior to updating our dialplan to stop using the AgentCallbackLogin(), we should logout our agent. We can do this simply from the dialplan like so.

```
*CLI> agent logoff Agent/100
Logging out 100
```

Then we can verify the agent is logged out, and no longer available in the queue.

```
*CLI> agent show
100          (Leif Madsen) not logged in (musiconhold is 'default')
101          (Russell Bryant) not logged in (musiconhold is 'default')
102          (Mark Michelson) not logged in (musiconhold is 'default')
3 agents configured [0 online , 3 offline]
```

```
*CLI> queue show
primary      has 0 calls (max unlimited) in 'ringall' strategy (1s holdtime)
Members:
Agent/102 (Unavailable) has taken no calls yet
Agent/101 (Unavailable) has taken no calls yet
Agent/100 (Unavailable) has taken 1 calls (last was 1543 secs ago)
No Callers
```



### Using AddQueueMember()


In order to stop using the AgentCallbackLogin(), we need to replace it with something. The something is the AddQueueMember() application. With this dialplan application, we can add channels to dial from the queue dynamically.

Lets create a simple dialplan to replace our existing dialplan which uses the AddQueueMember() dialplan application. The following dialplan will completely replace our existing dialplan. You can rename the existing extensions.conf and create a new file, and filling it with the following dialplan.

```
[general]
static=yes
writeprotect=no
clearglobalvars=no

[globals]
MY_QUEUES=primary

[default]

[from-devices]
; A replaced version of AgentCallbackLogin() using a GoSub()
;
exten => 999,1,Verbose(2,Logging in agent)
exten => 999,n,GoSub(AgentCallbackLogin,start,1)
exten => 999,n,Hangup()

; calling 'primary' queue
;
exten => 555,1,Verbose(2,Calling into the primary queue)
exten => 555,n,Playback(silence/1)
exten => 555,n,Queue(primary)
exten => 555,n,Hangup()

[agent_callback]
exten => _[A-Za-z0-9].,1,Set(EXTENSION=${EXTEN})
exten => _[A-Za-z0-9].,Goto(start,1)

exten => start,1,Dial(SIP/${EXTENSION})

[AgentCallbackLogin]
; conversion of AgentCallbackLogin() to using AddQueueMember()
;
exten => start,1,Verbose(2,Logging in agent)
exten => start,n,Playback(silence/1)
exten => start,n,Read(AGENT_USERID,agent-user)
exten => start,n,VMauthenticate(${AGENT_USERID}@default)
exten => start,n,AddQueueMember(${MY_QUEUES},Local/${CUT(CUT(CHANNEL,-,1),/,2)}@agent_callback,,,,${CUT(CHANNEL,-,1)})
exten => start,n,Playback(agent-loginok)
exten => start,n,Return()
```

At extension 999, we're using a GoSub() (which is similar to a Macro(), but without the restrictions of Macro(), and is recommended where possible). This GoSub() executes the dialplan located at the 'start' extension of the [AgentCallbackLogin] context.

After playing 1 second of silence (which is used to answer the channel so we don't have the first few milliseconds of our prompts cut off), we then prompt the agent to enter their agent ID (100). After pressing #, the value is saved to the AGENT_USERID channel variable. Asterisk then executes the VMauthenticate() application to authenticate the agent (more on configuring
this in a moment).

After we've successfully authenticated the agent, we then make them available in the queue by using the AddQueueMember() application. You'll notice that we've added the MY_QUEUES global variable which contains the name of the queue we are logging our agent into.

In more advanced dialplans, we may have multiple queues listed, separated by something like hyphen (-), and use the CUT() application, along with a While() loop to login the agent to multiple queues.

The second option to AddQueueMember() is the channel we want the Queue() application to call when it wishes to dial our agent. This is similar to how the AgentCallbackLogin() application works like we saw in Testing the Queue.

The nested CUT() statement is the same as we saw in Configuring the Dialplan, where the purpose is to take the value of the CHANNEL channel variable, and strip off the technology (SIP/) and the unique identifier (-017b24f0), leaving just the device name (00085D182ACF).

In the 6th position of the AddQueueMember() (the last option), we have another CUT() which strips off the unique identifier of the CHANNEL channel variable, leaving something like SIP/00085D182ACF. This option tells Asterisk to ignore the device state of the Local channel, and to look at the device state of the specified channel. Defining which channel to monitor for state is important because the Local channel is a pseudo channel, which can report an incorrect status, leading to agents who are unavailable when they should be.

After adding the member to the queue, we then playback a prompt that tells the agent they have been logged in successfully. We can verify our agent is now available by running the following command.

```
*CLI> queue show
primary      has 0 calls (max unlimited) in 'ringall' strategy (1s holdtime)
Members:
Local/00085D182ACF@agent_callback (dynamic) (Not in use) has taken no calls yet
No Callers
```



### Using voicemail.conf for Authentication


In the previous section, we used the VMauthenticate() application to perform the authentication of our queue member. In order to do this, we needed to add them to the voicemail.conf file, and give them a password. In many situations you will already have created a mailbox for your agents, and can simply use the existing voicemail configuration to perform the authentication. An advantage to this is that you no longer need to maintain a separate authentication file for your agents.

The voicemail.conf file we used was the default sample file installed when you run 'make samples' during Asterisk installation. We only changed the [default] voicemail context at the end to look like the following.

```
[default]
100 => 1234,Leif Madsen
101 => 1234,Russell Bryant
102 => 1234,Mark Michelson
```

Then we can reload app_voicemail to make our users available to the VMauthenticate() application for authentication.

```
*CLI> module reload app_voicemail.so
```

And verify our users exist.

```
*CLI> voicemail show users for default
Context    Mbox  User                      Zone       NewMsg
default    general New User                                  0
default    100   Leif Madsen                               0
default    101   Russell Bryant                            0
default    102   Mark Michelson                            0
```



### Conclusion


This article looked at what the AgentCallbackLogin() application gives us, how it is used, and how to perform the same functionality with the AddQueueMember() dialplan application. By doing this, you position yourself to utilize the preferred method of adding members to a queue, and using a 1.6.x compatible method.

Future articles will expand upon this most basic of functionality by providing dialplan for logging out queue members from the dialplan, pausing and unpausing members, and adding agents to more than one queue, and controlling their weight within those queues.

Questions and comments are welcomed and encouraged. Thanks for reading!
