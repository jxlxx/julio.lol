---
title: RADIUS Servers and AAA Basics
date: "2022-05-29"
description: A simple explaination of AAA servers, mostly freeRADIUS, and how to get started.
tldr: FreeRadius is an OSS implementation of a RADIUS server, which is a server that implements the RADIUS protocol to achieve AAA (Authorization, Authentication, Accounting).
draft: false
tags: ["networking", "radius"]
---

> ***free***Radius??? Maybe for you... It has cost me everything.


# What is RADIUS?

RADIUS is a network protocol.

Servers that accept and send the RADIUS protocol are called radius servers.

Everyone who has used the internet has probably interacted with a radius server. They are commonly used by ISPs, cellular network providers, and corporate/educational networks.

The primary functions of RADIUS is usually referred to as AAA.

1. Authentication
    - are the users/devices who they say they are?
    - validate some credentials
2. Authorization
    - are the users/devices allowed to use the network?
3. Accounting
    - track the usage of the network by users/devices
    
For example, Eduroam uses RADIUS servers.

If you’re trying to wrap your mind around OpenRoaming, just think about how Eduroam works.

https://eduroam.org/how/

https://wballiance.com/openroaming/how-it-works/

Here is a quick sketch of the physical hardware is involved:

| Component | Function | Hardware |
| --- | --- | --- | 
| User/device | Requests access to the network | laptop, phone, etc |
| Network Access Server (NAS) | Provides access to the network | Router, Switch, Access Point, VPN Terminator, etc |
| RADIUS Server | Receives authentication requests from the NAS. Returns authorization information to NAS. Recieves accounting information. | freeRADIUS, diameter, Radiator, ISE |

An important word to note is a NAS. A user/client/device interacts with something refered to as a NAS (Network Access Server) which is something like a router (but could be other things) and that device is what reaches out to the Radius server.


Another important word is **realm**. A realm tells radius what group/organization a user belongs to. Realms are reminisant of email addresses and are used in a somewhat similar way.

The format of a realm is `<USER-STRING>@<REALM>`.





# What is FreeRadius?

The most commonly used radius server is the freeRadius server. 

Setting up a freeRadius server consists of:
- editing various configuration files
- and including/excluding the right files. 

To run a freeRadius server you must:	
- put the config files in a file system where freeRadius is expecting them
- install the freeRadius software on a local machine, server, or container	 
- run it

Here is a simple example directory for a freeRadius configuration:

```
raddb/
    mods-available/...
    mods-enabled/...
    sites-available/...
    sites-enabled/...
    clients.conf
    proxy.conf
    radiusd.conf
```

Everything lives inside of a `raddb/` folder.


|  | |
|---|---|
|`mods-available`| directory contains sample configurations for all of the modules.|
|`mods-enabled` | enabled modules; sometimes these are just softlinks to the equivalent file in `mods-avaliable`|
|`mods-config` | extra configuration for modules|
|`sites-available` | this contains sample "virtual servers". Most of these will not be used. They exist as documentation and as examples of "best practices".|
|`sites-enabled` | this contains the configuration for "virtual servers" that are being used by the server.|

The rest of the conf files allow to define how the server listens to requests and what it does with with them.

The `radiusd.conf` file contains the server configuration.

The `proxy.conf` file controls the servers behaviour towards ALL other servers to which it sends proxy requests.

The `clients.conf` file defines RADIUS clients (usually a NAS, Access Point, etc.) by specifying parts and protocols.


In general the syntax of the configuration files looks something like this:

```

server name_of_server {
	an_authentication_mod

	huh {
		WHAT
	}
}

```

But it depends on what you are configuring exactly.


## Sections

Configuration files are broken up into something called "sections" or sometimes "blocks."

```
this_is_a_section {

}
```

Some important sections:
- `server` 
- `client`
- `security`
- `logging`
- ... etc


Some important subsections with a `server` section:
- `authorize`
- `authenticate`
- `pre-accounting`
- `accounting`
- `post-accounting`
- `proxy`
- ... etc



## Helpful FreeRadius Documentation 

- [Technical Guide](https://networkradius.com/doc/FreeRADIUS%20Technical%20Guide.pdf)
- [Getting Started FreeRadius](https://wiki.freeradius.org/guide/Getting%20Started)
	

# Authentication  

The radius server receives a request and decides what to do with it. It decides based on:

- what authentication types you have enabled in the server
- what the server can look up in a DB
- what’s in the request

The server starts by querying the modules in the authorize section:

- `unix` module, can you do this?
- `pap` module, can you do this?
- `mschap` module can you do this?
- etc.

Until there is some kind of match by one of the modules.
A module will find a match by searching the request for key attributes, such as `MS-CHAP-Challenge` (for `mschap`) or `EAP-Message` (for `eap`), etc.
If the module does find a match, it sets the `Auth-Type` to itself.
For example, suppose that the user sent a request with a `User-Password` attribute and `pap` is enabled. The pap module will have set `Auth-Type=pap`.
At the end of the authorize step, the server will check if anything set the `Auth-Type` if not, it will immediately reject the request.

If anything is missing or in the wrong form?  → reject 🗑

The naming of the `authorize` section is kind of misleading. This is really more like a pre-authentication step.

Radius servers can also proxy requests to other servers to do the actual authentication.

## Network Access Server

The NAS acts as the gateway between the user and the wider network.

The NAS will send the users request to access the network to the Radius server. The server will try to authenticate user give the information in the request. After that, the radius server will instruct the NAS whether to allow access to the user and how much.

The NAS acts as the gateway router and firewall for that user.

This means that the server simply returns a decision to the NAS, but it’s up to the NAS to enforce it.

**There is nothing the radius server can do to make the NAS behave as intended.**	

The radius server receives a request and decides what to do with it. Its decision is based on:
- what authentication types you have enabled in the server
- what the server can look up in a DB
- what’s in the request

The server cannot request additional information from the NAS, so it has to decided what to do with the information it has. It figures out what to with via policies. A policy can be something like “accept anyone with a correct username/password combo.” Or more complicated like: “allow basic users to request premium services in non-premium hours, except for Sundays and holidays, so long as their payment status is up to date”

## Radius Dictionaries

Radius is a binary-based protocol, not a text-based one. so when we are talking about attributes in the request, like `User-Name` they are actually encoded in the message as binary data. Dictionary files are used to map between the names used by people and the binary data in the RADIUS packets.

Packets sent to/from a NAS contain: a number, length, and binary data.

A dictionary file is a list of entries, each of which contain: a name, a number, and a data type.

The server uses the dictionary like this: 
- it searches the dictionaries to match the number in the packet 
- the corresponding data type is used by the server to interpret the data type 
- and the name is used in all the debug/logging messages.

Note that the NAS and server may use different dictionaries, which may cause problems.

Also note that servers require access to a vendor dictionary to understand vendor attributes.

## `radiusd.conf`

The `radiusd.conf` file contains the server configuration.

The "unlang" policy language can be used to create complex `if / else` policies. 

The client configuration is defined in `clients.conf`.

## Configuration File Syntax

Configuration files are UTF-8 text.

They are line-orientated, meaning everything has to be on a separate line.

A configuration item is an internal variable that has a name and holds a value.

```
variable = value
```

Variables have data types. The can be IP addresses, strings, number, etc.

Portions of the configuration can be grouped in sections:

```
texas {
  dallas = yes
  houston = no
  san_antonio = 70
}
```

A configuration file can load another configuration file via the `$INCLUDE` statement:

```
$INCLUDE other.conf
```

Or a directories. Note that dotfiles `.imadotfile.conf` are ignored but editor “backup” files with tildes `~backup.conf` are not. Also this is how you reuse variable definitions:

```
somedir = "hello"
$INCLUDE ${somedir}/foo/bar/baz
```

Variable references `${var_name}` act as macros, and expand when the server loads.

This is different from run-time expansion, which is done like this: `%{...}`

You can also use environment variables:

```
$ENV{variable}
```

And here’s weird one for fun: 

```
${reference1[name].reference2}
```

Sections can have instance names:

```
section-type instance-name {
    [ statements ]
}
```

For example, the `client` section is used to define information about a client. When multiple clients are defined, they are distinguished by their `instance-name`.

### Booleans are weird in radius.

The boolean data type contains a true or false value. The values `yes`, `on`, and `1` evaluate to *true.* The values `no`, `off`, and `0` evaluate to *false*.

```
var = yes 
```

### Delay is a data type

Delay is a data type. It contains fractional numbers, like `1.4`. These numbers are base 10. Usually they are used for timers. The resolution of delay is no more than microseconds, but usually in milliseconds.

### Words

A *word* string is composed of one word, without any surrounding quotes, such as `iamaword123`

### Strings

Strings can have single or double quotes, or back-ticks.

The main difference between the single and double quoted strings is that the double quoted strings can be dynamically expanded.

The syntax `${…}`  is used for parse-time expansion and `%{…}` is used for run-time expansion.

## Some Variables


|keyword|meaning|
|-------|-------|
|`checkrad`| Checkrad is used by the radius server to check if its idea of a user logged in on a certain port/NAS is correct if a double login is detected.|
|`cleanup_delay`| The time to wait (in seconds) before “cleaning up” a reply that was sent to the NAS. |
|`hostname_lookups`| Default is no, enabled it mean DNS requests which may take super long and block other requests.|
|`libdir`| The libdir is where to find the `rlm_*` modules.|
|`max_request_time`|Maximum seconds to handle a request.|
|`max_requests`| The maximum number of requests of which the server keeps track of.|
|`panic_action`| What to do when panic. Its a string.|
|`pidfile`| Where to store the PID of the server. To make killing it easier.|



### `cleanup_delay`
The request and replay are usually cached intenally for a short period of time after the reply is sent to the NAS. If the packets gets lost or something, the NAS might send a re-send the request. If too low, then it’s useless. If it’s too high, then the server will cache too many requests and some new requests may get blocked (see `max_requests`).


# Security Configuration

These directives go into a security section, like so:

```
security {
	...
}
```

I left out a lot but here are some interesting ones:

|||
|---|---|
| `reject_delay`| Seconds to wait before sending an `Access-Reject`. Slows down DDoS attack and slows down brute force password cracking.|
|`status_server`| Boolean. Whether to respond to Status-Server requests. See also: `raddb/sites-available/status`|

## Thread pool

The thread pool is a long-lived group of threads that take turns (round-robin) handling any incoming requests.

### **`max_requests_per_server`**

Default is 0.

The documentation says: There may be memory leaks or resource allocation problems with the server. If so, set this value to approximately 300 so that the resources will be cleaned up periodically. Not sure what the tradeoff is... do the request after 300 get dropped?

Also: '0' is a special value meaning '*infinity*' or '*the servers never exit*'.

# Virtual Servers

A virtual server is a (nearly complete) RADIUS server.

FreeRADIUS can run multiple virtual servers at the same time. 

Virtual servers can even proxy requests to each other.

The simplest way to define a virtual server would be to take all of the request processing sections from `radius.conf` (`authorize` , `authenticate`, etc.) and wrap them in a `server {}` block.

```
server foo {
		listen {
			ipaddr = 127.0.0.1
			port = 2000
			type = auth
		}

		authorize {
			update control {
				Cleartext-Password := "bob"
			}
			pap
		}

		authenticate {
			pap
		}
	}
```

Only certain sub-sections can appear in a virtual server section:

- `listen`
- `client`
- `authorize`
- `authenticate`
- `port-auth`
- `pre-proxy`
- `post-proxy`
- `preacct`
- `accounting`
- `session`

When a `listen` section is inside of a virtual server definition, it means that all requests sent to that IP/port will be processed through the virtual server. There can not be two `listen` sections with the same IP address and port number.

### Authorization Section

The name of this section is authorize for historical reasons, as earlier versions of the server did not have a `post-auth section`. A more accurate description of this section would be `pre-authentication`.

The authorize section processes `Access-Request` packets by normalizing the request, determining
which authentication method to use, and either setting the “known good” password (the valid password found in the database) for the user or informing the server that the request should be proxied.

Once the authorize section has finished processing the packet, the return code for the section is examined by the server. If the return code is `noop`, `notfound`, `ok`, or `updated`, then request processing continues.

If the return code is `handled`, then it is presumed that one of the modules set the contents of the reply, and the server sends the reply message. 

Otherwise, the server treats the authentication as being rejected and runs the `post-auth` section.

If the authentication has not been rejected, then the server continues processing the request by
searching for the `Auth-Type` attribute. Then the named sub-section of `authenticate` is executed. 

The authorization section is starts when the server receives an `Access-Request` packet.

First preprocesses (`hints` and `huntgroups`), then does `realms`, then finally the `users` file.

The order of the realm modules will determine the order in which a matching realm is found. 

```
authorize {
  filter-username
  preprocess
  # operator-name
  # cui
  # authlog
  chap
  mschap
	digest
	# mimax
	# IPASS
	suffix 
  ntdomain
  eap {
		ok = return
  }
  # unix
  files
  -sql
  # smbpasswd
  -ldap
  # daily
	expiration
	logintime
	pap
	Autz-Type Status-Server {
  
	}
}
```

`filter-username` this is a policy that sanitizing usernames in requests by removing garbage like spaces and invalid characters. If it appears invalid, the request is rejected. 

See `policy.d/filter` for the definition of the `filter-username` policy.

`preprocess` sanitizes the non-standard format attributes in the request and makes them standard.

(I think that this mean like how a mac address can be written in like 6953 different ways)

If `CUI` is used then `Operator-Name` is required to be set for CUI generation.

Not sure what this means or why it is true.

`auth_log` generates a log of authentication requests.

`chap` sets `Auth-Type := CHAP` for requests which contain a `CHAP-Password` attribute.

When users log in with an `MS-CHAP-Challenge` attribute for authentication, the `mschap` module finds the `MS-CHAP-Challenge attribute` and adds `Auth-Type := MS-CHAP` to the request, which causes the server to then use the `mschap` module for authentication.

`digest`is for SIP (session initiation protocol) servers. (VoIP). who cares.

WiMAX refers to implementations of the [IEEE 802.16](https://en.wikipedia.org/wiki/IEEE_802.16) family of wireless-networks standards created by the WiMAX Forum. The WiMAX specification states that the `Calling-Station-Id` is 6 octets of the MAC.

This definition conflicts with with all common RADIUS practices. Uncommenting the `wimax` module here means that it will fix the `Calling-Station-Id` attribute to the normal format. whatever.


💡 ***Did you know***: WiMAX was sometimes referred to as "Wi-Fi on steroids"[[5]](https://en.wikipedia.org/wiki/WiMAX#cite_note-5) lol


Looks for `IPASS`-style `realm/` and, if not found, looks for `@realm` and decides whether or not to proxy based on those results.

When using multiple kinds of realms, set `ignore_null = yes` for all of them. Otherwise, if the first style of realm doesn’t match, then the other styles won’t be checked.

The `eap` module takes care of `EAP-MD5`, `EAP-TLS`, and `EAP-LEAP` authentication.

`unix` pulls crypt’d passwords from `/etc/passwd` or `/etc/shadow` using the system APIs to get the password.

`files` reads the `radbb/users` file.

The `-sql`  module looks in an SQL database. I don’t know why it gets a dash, but `-ldap` gets one too, so maybe its a theme.

... skipping a couple idc

`daily` enforces daily limits on time spent logged in. I think it requires `expiration` and `logintime`

If no other module has claimed responsibility for authentication, then try `pap`. This process allows the other modules listed above to only add a "known good" password to the request and nothing else. The PAP module will then see that password and use it to do PAP authentication. This module should be listed last so that the other modules get a chance to set `Auth-Type` for themselves.

If `status_server = yes`, then `Status-Server` messages are passed through the following section and **only** the following section.

```
Autz-Type Status-Server {

}
```

### Authentication Section

This section lists those modules that are available for authentication. 

Note that the order of modules listed below does **not** mean “try each module in order”. 

Instead, a module from the `authorize` section adds a configuration attribute `Auth-Type := FOO`. That authentication type is then used to pick the appropriate module from the list below.

The authenticate section is only used when the server is authenticating requests locally and is
bypassed completely when proxying.

This section is different from each of the other sections: it is composed of a series of subsections, only one of which is executed.

The `Auth-Type` attribute can also refer to a module (e.g. `eap`) instead of a subsection, in which case that module, and only that module, is processed.

A simple example:

```
authenticate {
	Auth-Type PAP {
		pap
	}
	Auth-Type MS-CHAP {
		mschap
	}
	Auth-Type CHAP {
		chap
	}
	eap
}
```

In general, the `Auth-Type` attribute **should not** be set. The server will figure it out on its own and will do the right thing. The above is just defining `Auth-Types` but not actually setting the attribute.

Do not put `unlang` configurations into the `authenticate` section. Put them in the `post-auth` section instead. That’s what the `post-auth` section is for.

### Pre-accounting Section

This section decides which accounting type to use.

Session start times are **implied** in RADIUS. The NAS never sends a "start time". Instead, it sends a start packet, **possibly** with an Acct-Delay-Time.

You can create a start time with the following code:

```
update request {
	FreeRADIUS-Acct-Session-Start-Time = "%{expr: %l - %\{%{Acct-Session-Time}:-0} - %\{%{Acct-Delay-Time}:-0}}"
}
```

`acct_unique` ensures that a semi-unique identifier is available for every request because many NAS boxes are broken.

The `files`  module reads the `acct_user` file.

### Accounting Section

The `accounting` section Iogs the accounting data.

`cui` updates accounting packets by adding the `CUI` attribute from the corresponding `Access-Accept`. It's used for when the NAS doesn’t support CUI themselves.

`detail` creates a ``detail``'ed log of the packets.

`-sql` logs traffic into a SQL db.

`exec` is for `Exec-Program` and `Exec-Program-Wait`.

### Post-authentication Section

Once it is **verified** that the user has been authenticated, there are additional steps that can be taken.

### Pre-proxy Section

TODO

### Post-proxy Section

TODO

# What is an inner-tunnel
TODO
# What is an IdP
TODO
